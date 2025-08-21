#!/usr/bin/env python3
"""
Retry utilities with exponential backoff and circuit breaker pattern.

@implements FR-045: Retry Mechanism with exponential backoff
"""
import time
import random
import functools
from typing import Callable, Any, Optional, Tuple, Type
from datetime import datetime, timedelta

class CircuitBreaker:
    """
    Circuit breaker pattern to prevent cascading failures.
    Opens after threshold failures, preventing further attempts.
    """
    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "closed"  # closed, open, half-open
    
    def is_open(self) -> bool:
        """Check if circuit breaker is open (blocking calls)"""
        if self.state == "closed":
            return False
        
        if self.state == "open":
            # Check if recovery timeout has passed
            if self.last_failure_time:
                if datetime.now() - self.last_failure_time > timedelta(seconds=self.recovery_timeout):
                    self.state = "half-open"
                    return False
            return True
        
        return False  # half-open allows one attempt
    
    def record_success(self):
        """Record successful call"""
        if self.state == "half-open":
            self.state = "closed"
        self.failure_count = 0
    
    def record_failure(self):
        """Record failed call"""
        self.failure_count += 1
        self.last_failure_time = datetime.now()
        
        if self.failure_count >= self.failure_threshold:
            self.state = "open"

class RetryConfig:
    """Configuration for retry behavior"""
    def __init__(
        self,
        max_retries: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 32.0,
        exponential_base: float = 2.0,
        jitter: bool = True,
        circuit_breaker: Optional[CircuitBreaker] = None
    ):
        self.max_retries = max_retries
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.exponential_base = exponential_base
        self.jitter = jitter
        self.circuit_breaker = circuit_breaker

def calculate_backoff_delay(
    attempt: int,
    base_delay: float = 1.0,
    exponential_base: float = 2.0,
    max_delay: float = 32.0,
    jitter: bool = True
) -> float:
    """
    Calculate exponential backoff delay with optional jitter.
    
    Args:
        attempt: Current attempt number (0-based)
        base_delay: Initial delay in seconds
        exponential_base: Base for exponential calculation
        max_delay: Maximum delay cap
        jitter: Add randomization to prevent thundering herd
    
    Returns:
        Delay in seconds
    """
    # Calculate exponential delay
    delay = min(base_delay * (exponential_base ** attempt), max_delay)
    
    # Add jitter if enabled (±25% randomization)
    if jitter:
        jitter_range = delay * 0.25
        delay = delay + random.uniform(-jitter_range, jitter_range)
    
    return max(0, delay)  # Ensure non-negative

def is_transient_error(exception: Exception) -> bool:
    """
    Determine if an error is transient and should be retried.
    
    Args:
        exception: The exception to check
    
    Returns:
        True if error is transient and retry may help
    """
    transient_errors = [
        "ConnectionError",
        "TimeoutError", 
        "TemporaryFailure",
        "DatabaseLocked",
        "ResourceUnavailable",
        "TooManyRequests"
    ]
    
    error_name = exception.__class__.__name__
    error_msg = str(exception).lower()
    
    # Check error type
    if error_name in transient_errors:
        return True
    
    # Check error message for patterns
    transient_patterns = [
        "timeout",
        "temporary",
        "locked",
        "unavailable",
        "rate limit",
        "too many",
        "connection reset",
        "broken pipe"
    ]
    
    return any(pattern in error_msg for pattern in transient_patterns)

def retry_with_backoff(
    func: Callable,
    config: Optional[RetryConfig] = None,
    on_retry: Optional[Callable] = None,
    on_failure: Optional[Callable] = None
) -> Any:
    """
    Execute function with retry logic and exponential backoff.
    
    Args:
        func: Function to execute
        config: Retry configuration
        on_retry: Callback for retry attempts (gets attempt number and exception)
        on_failure: Callback for final failure (gets exception)
    
    Returns:
        Function result if successful
    
    Raises:
        Last exception if all retries exhausted
    """
    if config is None:
        config = RetryConfig()
    
    # Check circuit breaker
    if config.circuit_breaker and config.circuit_breaker.is_open():
        raise Exception("Circuit breaker is open - service unavailable")
    
    last_exception = None
    
    for attempt in range(config.max_retries + 1):
        try:
            result = func()
            
            # Record success with circuit breaker
            if config.circuit_breaker:
                config.circuit_breaker.record_success()
            
            return result
            
        except Exception as e:
            last_exception = e
            
            # Check if error is transient
            if not is_transient_error(e):
                # Non-transient error, don't retry
                if config.circuit_breaker:
                    config.circuit_breaker.record_failure()
                raise
            
            # Check if we have retries left
            if attempt < config.max_retries:
                # Calculate backoff delay
                delay = calculate_backoff_delay(
                    attempt,
                    config.base_delay,
                    config.exponential_base,
                    config.max_delay,
                    config.jitter
                )
                
                # Call retry callback if provided
                if on_retry:
                    on_retry(attempt + 1, e, delay)
                
                # Wait before retry
                time.sleep(delay)
            else:
                # No more retries
                if config.circuit_breaker:
                    config.circuit_breaker.record_failure()
                
                if on_failure:
                    on_failure(e)
                
                raise

def retry_decorator(
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 32.0,
    exponential_base: float = 2.0,
    jitter: bool = True,
    circuit_breaker: Optional[CircuitBreaker] = None,
    retry_on: Optional[Tuple[Type[Exception], ...]] = None
):
    """
    Decorator for adding retry logic to functions.
    
    Usage:
        @retry_decorator(max_retries=3, base_delay=1.0)
        def my_function():
            # Function that may fail transiently
            pass
    """
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            config = RetryConfig(
                max_retries=max_retries,
                base_delay=base_delay,
                max_delay=max_delay,
                exponential_base=exponential_base,
                jitter=jitter,
                circuit_breaker=circuit_breaker
            )
            
            def execute():
                return func(*args, **kwargs)
            
            def on_retry(attempt, exception, delay):
                print(f"Retry {attempt}/{max_retries} after {delay:.2f}s - {exception}")
            
            return retry_with_backoff(
                execute,
                config,
                on_retry=on_retry
            )
        
        return wrapper
    
    return decorator

# Example usage
if __name__ == "__main__":
    import random
    
    # Simulate a flaky function
    @retry_decorator(max_retries=3, base_delay=1.0)
    def flaky_function():
        if random.random() < 0.7:  # 70% failure rate
            raise ConnectionError("Connection failed")
        return "Success!"
    
    # Test retry logic
    try:
        result = flaky_function()
        print(f"Result: {result}")
    except Exception as e:
        print(f"Final failure: {e}")
    
    # Test backoff calculation
    print("\nBackoff delays:")
    for i in range(5):
        delay = calculate_backoff_delay(i, base_delay=1.0, jitter=False)
        print(f"  Attempt {i+1}: {delay:.2f}s")