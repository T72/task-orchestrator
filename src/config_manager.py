"""
Configuration Management for Task Orchestrator Core Loop features.
Provides feature toggles and settings persistence.
"""

import os
import yaml
from pathlib import Path
from typing import Dict, Any, Optional


class ConfigManager:
    """Manages Core Loop configuration and feature toggles."""
    
    # Default configuration
    DEFAULT_CONFIG = {
        'features': {
            'success-criteria': True,
            'feedback': True,
            'telemetry': True,
            'completion-summaries': True,
            'time-tracking': True,
            'deadlines': True
        },
        'minimal_mode': False,
        'telemetry_enabled': True,
        'version': '2.3.0'
    }
    
    # Valid feature names
    VALID_FEATURES = {
        'success-criteria', 'feedback', 'telemetry', 
        'completion-summaries', 'time-tracking', 'deadlines'
    }
    
    def __init__(self, config_path: str = None):
        """Initialize configuration manager."""
        if config_path:
            self.config_path = Path(config_path)
        else:
            self.config_path = Path.home() / ".task-orchestrator" / "config.yaml"
        
        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        self.config = self._load_config()
    
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from file or create default."""
        if self.config_path.exists():
            try:
                with open(self.config_path, 'r') as f:
                    config = yaml.safe_load(f) or {}
                    # Merge with defaults to ensure all keys exist
                    return self._merge_with_defaults(config)
            except Exception as e:
                print(f"Warning: Failed to load config: {e}")
                return self.DEFAULT_CONFIG.copy()
        else:
            # Create default config file
            self._save_config(self.DEFAULT_CONFIG)
            return self.DEFAULT_CONFIG.copy()
    
    def _merge_with_defaults(self, config: Dict) -> Dict:
        """Merge loaded config with defaults to ensure all keys exist."""
        merged = self.DEFAULT_CONFIG.copy()
        
        # Deep merge
        if 'features' in config:
            merged['features'].update(config['features'])
        if 'minimal_mode' in config:
            merged['minimal_mode'] = config['minimal_mode']
        if 'telemetry_enabled' in config:
            merged['telemetry_enabled'] = config['telemetry_enabled']
        
        return merged
    
    def _save_config(self, config: Dict = None):
        """Save configuration to file."""
        if config is None:
            config = self.config
        
        try:
            with open(self.config_path, 'w') as f:
                yaml.safe_dump(config, f, default_flow_style=False, sort_keys=False)
        except Exception as e:
            print(f"Warning: Failed to save config: {e}")
    
    def enable_feature(self, feature: str) -> bool:
        """Enable a specific Core Loop feature."""
        if feature not in self.VALID_FEATURES:
            raise ValueError(f"Unknown feature: {feature}. Valid features: {', '.join(self.VALID_FEATURES)}")
        
        self.config['features'][feature] = True
        self.config['minimal_mode'] = False  # Disable minimal mode when enabling features
        self._save_config()
        return True
    
    def disable_feature(self, feature: str) -> bool:
        """Disable a specific Core Loop feature."""
        if feature not in self.VALID_FEATURES:
            raise ValueError(f"Unknown feature: {feature}. Valid features: {', '.join(self.VALID_FEATURES)}")
        
        self.config['features'][feature] = False
        self._save_config()
        return True
    
    def is_feature_enabled(self, feature: str) -> bool:
        """Check if a feature is enabled."""
        # Minimal mode overrides all features
        if self.config.get('minimal_mode', False):
            return False
        
        return self.config.get('features', {}).get(feature, True)
    
    def set_minimal_mode(self, enabled: bool = True):
        """Enable or disable minimal mode (disables all Core Loop features)."""
        self.config['minimal_mode'] = enabled
        self._save_config()
    
    def is_minimal_mode(self) -> bool:
        """Check if minimal mode is enabled."""
        return self.config.get('minimal_mode', False)
    
    def reset_to_defaults(self):
        """Reset configuration to default values."""
        self.config = self.DEFAULT_CONFIG.copy()
        self._save_config()
    
    def get_all_settings(self) -> Dict[str, Any]:
        """Get all current configuration settings."""
        return self.config.copy()
    
    def get_feature_status(self) -> Dict[str, bool]:
        """Get status of all features."""
        if self.is_minimal_mode():
            # All features disabled in minimal mode
            return {feature: False for feature in self.VALID_FEATURES}
        
        return self.config.get('features', {}).copy()
    
    def enable_telemetry(self):
        """Enable telemetry collection."""
        self.config['telemetry_enabled'] = True
        self.config['features']['telemetry'] = True
        self._save_config()
    
    def disable_telemetry(self):
        """Disable telemetry collection."""
        self.config['telemetry_enabled'] = False
        self.config['features']['telemetry'] = False
        self._save_config()
    
    def is_telemetry_enabled(self) -> bool:
        """Check if telemetry is enabled."""
        if self.is_minimal_mode():
            return False
        return self.config.get('telemetry_enabled', True) and \
               self.config.get('features', {}).get('telemetry', True)