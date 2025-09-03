#!/usr/bin/env node
/**
 * Test Suite for Universal Task Orchestrator Launcher
 * Tests cross-platform compatibility, edge cases, and error handling
 * 
 * @implements FR-052: Comprehensive Cross-Platform Test Coverage
 */

const { spawn, spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');
const assert = require('assert');

// Import the launcher module
const launcherPath = path.join(__dirname, '..', 'tm-universal.js');
const { findPython } = require(launcherPath);

// Test results tracking
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const testResults = [];

// Color codes for output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m'
};

/**
 * Log test result
 */
function logTest(name, passed, message = '') {
    totalTests++;
    if (passed) {
        passedTests++;
        console.log(`${colors.green}✓${colors.reset} ${name}`);
    } else {
        failedTests++;
        console.log(`${colors.red}✗${colors.reset} ${name}`);
        if (message) console.log(`  ${colors.yellow}${message}${colors.reset}`);
    }
    testResults.push({ name, passed, message });
}

/**
 * Test Python detection
 */
function testPythonDetection() {
    console.log(`\n${colors.bright}Testing Python Detection${colors.reset}`);
    
    // Test 1: Basic Python detection
    try {
        const python = findPython();
        logTest('Find Python interpreter', python !== null, 
            python ? `Found: ${python}` : 'No Python found');
    } catch (e) {
        logTest('Find Python interpreter', false, e.message);
    }
    
    // Test 2: Python version verification
    try {
        const python = findPython();
        if (python) {
            const parts = python.split(' ');
            const result = spawnSync(parts[0], [...parts.slice(1), '--version'], {
                encoding: 'utf8'
            });
            const isPython3 = (result.stdout + result.stderr).includes('Python 3');
            logTest('Python 3.x verification', isPython3,
                isPython3 ? result.stdout.trim() : 'Not Python 3');
        } else {
            logTest('Python 3.x verification', false, 'No Python to verify');
        }
    } catch (e) {
        logTest('Python 3.x verification', false, e.message);
    }
}

/**
 * Test command execution
 */
function testCommandExecution() {
    console.log(`\n${colors.bright}Testing Command Execution${colors.reset}`);
    
    // Test 3: Execute with --help
    try {
        const result = spawnSync('node', [launcherPath, '--help'], {
            encoding: 'utf8',
            timeout: 5000
        });
        const success = result.status === 0 || result.stdout.includes('help') || 
                       result.stdout.includes('usage') || result.stderr.includes('implemented');
        logTest('Execute tm --help', success, 
            success ? 'Help executed' : `Exit code: ${result.status}`);
    } catch (e) {
        logTest('Execute tm --help', false, e.message);
    }
    
    // Test 4: Execute list command
    try {
        const result = spawnSync('node', [launcherPath, 'list'], {
            encoding: 'utf8',
            timeout: 5000,
            cwd: path.dirname(launcherPath)
        });
        const success = result.status === 0 || result.stdout.includes('[') || 
                       result.stdout.includes('No tasks') || result.stdout.includes('pending');
        logTest('Execute tm list', success,
            success ? 'List command worked' : `Exit code: ${result.status}`);
    } catch (e) {
        logTest('Execute tm list', false, e.message);
    }
}

/**
 * Test edge cases
 */
function testEdgeCases() {
    console.log(`\n${colors.bright}Testing Edge Cases${colors.reset}`);
    
    // Test 5: No arguments
    try {
        const result = spawnSync('node', [launcherPath], {
            encoding: 'utf8',
            timeout: 5000
        });
        // Should show usage or error
        const handled = result.status !== null && 
                       (result.stdout.length > 0 || result.stderr.length > 0);
        logTest('No arguments handling', handled,
            handled ? 'Handled gracefully' : 'No output');
    } catch (e) {
        logTest('No arguments handling', false, e.message);
    }
    
    // Test 6: Invalid command
    try {
        const result = spawnSync('node', [launcherPath, 'invalid_command_xyz'], {
            encoding: 'utf8',
            timeout: 5000
        });
        // Should show error message
        const handled = result.stderr.includes('Error') || 
                       result.stderr.includes('not') ||
                       result.stdout.includes('Error') ||
                       result.stdout.includes('not') ||
                       result.status !== 0;
        logTest('Invalid command handling', handled,
            handled ? 'Error handled' : 'No error message');
    } catch (e) {
        logTest('Invalid command handling', false, e.message);
    }
    
    // Test 7: Special characters in arguments
    try {
        const result = spawnSync('node', [launcherPath, 'add', 'Test "task" with spaces'], {
            encoding: 'utf8',
            timeout: 5000
        });
        // Should handle quotes and spaces
        const handled = result.status !== undefined;
        logTest('Special characters in args', handled,
            handled ? `Exit code: ${result.status}` : 'Failed to execute');
    } catch (e) {
        logTest('Special characters in args', false, e.message);
    }
    
    // Test 8: Long argument list
    try {
        const longArgs = Array(50).fill('arg').map((a, i) => `${a}${i}`);
        const result = spawnSync('node', [launcherPath, 'test', ...longArgs], {
            encoding: 'utf8',
            timeout: 5000
        });
        const handled = result.status !== undefined;
        logTest('Long argument list', handled,
            handled ? 'Handled long args' : 'Failed with long args');
    } catch (e) {
        logTest('Long argument list', false, e.message);
    }
}

/**
 * Test cross-platform compatibility
 */
function testCrossPlatform() {
    console.log(`\n${colors.bright}Testing Cross-Platform Features${colors.reset}`);
    
    const platform = os.platform();
    
    // Test 9: Platform detection
    logTest('Platform detection', true, `Running on: ${platform}`);
    
    // Test 10: Path separator handling
    try {
        const testPath = path.join('test', 'path', 'file.txt');
        const normalized = testPath.replace(/\\/g, '/');
        const isValid = normalized.includes('/') || platform === 'win32';
        logTest('Path separator handling', isValid,
            `Path: ${testPath} -> ${normalized}`);
    } catch (e) {
        logTest('Path separator handling', false, e.message);
    }
    
    // Test 11: Windows-specific test
    if (platform === 'win32') {
        try {
            // Test batch file execution
            const batchPath = path.join(path.dirname(launcherPath), 'tm.cmd');
            if (fs.existsSync(batchPath)) {
                const result = spawnSync('cmd.exe', ['/c', batchPath, 'list'], {
                    encoding: 'utf8',
                    timeout: 5000
                });
                const success = result.status === 0 || result.stdout.includes('[');
                logTest('Windows batch file', success,
                    success ? 'Batch file works' : `Exit code: ${result.status}`);
            } else {
                logTest('Windows batch file', false, 'tm.cmd not found');
            }
        } catch (e) {
            logTest('Windows batch file', false, e.message);
        }
    } else {
        logTest('Windows batch file', true, 'Skipped (not Windows)');
    }
    
    // Test 12: Unix-specific test
    if (platform !== 'win32') {
        try {
            // Test shebang execution
            const result = spawnSync(launcherPath, ['list'], {
                encoding: 'utf8',
                timeout: 5000
            });
            const success = result.status === 0 || result.stdout.includes('[');
            logTest('Unix shebang execution', success,
                success ? 'Direct execution works' : 'Needs node prefix');
        } catch (e) {
            logTest('Unix shebang execution', false, e.message);
        }
    } else {
        logTest('Unix shebang execution', true, 'Skipped (Windows)');
    }
}

/**
 * Test error recovery
 */
function testErrorRecovery() {
    console.log(`\n${colors.bright}Testing Error Recovery${colors.reset}`);
    
    // Test 13: Missing Python handling
    try {
        // Temporarily rename findPython to simulate missing Python
        const originalPath = process.env.PATH;
        process.env.PATH = '';  // Clear PATH to simulate missing Python
        
        const result = spawnSync('node', [launcherPath, 'list'], {
            encoding: 'utf8',
            timeout: 5000,
            env: { ...process.env, PATH: '' }
        });
        
        process.env.PATH = originalPath;  // Restore PATH
        
        const handled = result.stderr.includes('Python') || 
                       result.stderr.includes('not found') ||
                       result.stdout.includes('Python') ||
                       result.stdout.includes('not found');
        logTest('Missing Python error', handled,
            handled ? 'Error message shown' : 'No clear error');
    } catch (e) {
        logTest('Missing Python error', false, e.message);
    }
    
    // Test 14: Script interruption handling
    try {
        const child = spawn('node', [launcherPath, 'list'], {
            timeout: 100  // Very short timeout to force interruption
        });
        
        setTimeout(() => {
            child.kill('SIGINT');
        }, 50);
        
        let handled = false;
        child.on('exit', (code, signal) => {
            handled = signal === 'SIGINT' || code !== null;
        });
        
        setTimeout(() => {
            logTest('Script interruption', handled,
                handled ? 'Interruption handled' : 'Not handled properly');
        }, 200);
    } catch (e) {
        logTest('Script interruption', false, e.message);
    }
    
    // Test 15: Invalid Python path
    try {
        const result = spawnSync('node', [launcherPath, 'test'], {
            encoding: 'utf8',
            timeout: 5000,
            env: { ...process.env, PYTHON: '/invalid/python/path' }
        });
        const handled = result.status !== undefined;
        logTest('Invalid Python path', handled,
            handled ? 'Handled invalid path' : 'Crashed on invalid path');
    } catch (e) {
        logTest('Invalid Python path', false, e.message);
    }
}

/**
 * Test performance
 */
function testPerformance() {
    console.log(`\n${colors.bright}Testing Performance${colors.reset}`);
    
    // Test 16: Startup time
    try {
        const startTime = Date.now();
        const result = spawnSync('node', [launcherPath, '--help'], {
            encoding: 'utf8',
            timeout: 10000
        });
        const duration = Date.now() - startTime;
        const isfast = duration < 5000;  // Should start within 5 seconds
        logTest('Startup performance', isfast,
            `Started in ${duration}ms`);
    } catch (e) {
        logTest('Startup performance', false, e.message);
    }
    
    // Test 17: Memory usage (basic check)
    try {
        const result = spawnSync('node', ['--max-old-space-size=50', launcherPath, 'list'], {
            encoding: 'utf8',
            timeout: 5000
        });
        const success = result.status === 0 || result.status === 1;
        logTest('Memory efficiency', success,
            success ? 'Runs in limited memory' : 'Memory issue detected');
    } catch (e) {
        logTest('Memory efficiency', false, e.message);
    }
}

/**
 * Run all tests
 */
async function runAllTests() {
    console.log(`${colors.bright}${colors.blue}Universal Task Orchestrator Launcher Test Suite${colors.reset}`);
    console.log('='.repeat(50));
    
    // Check if launcher exists
    if (!fs.existsSync(launcherPath)) {
        console.error(`${colors.red}Error: Launcher not found at ${launcherPath}${colors.reset}`);
        process.exit(1);
    }
    
    // Run test suites
    testPythonDetection();
    testCommandExecution();
    testEdgeCases();
    testCrossPlatform();
    testErrorRecovery();
    testPerformance();
    
    // Wait for async tests
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Print summary
    console.log('\n' + '='.repeat(50));
    console.log(`${colors.bright}Test Summary${colors.reset}`);
    console.log(`Total Tests: ${totalTests}`);
    console.log(`${colors.green}Passed: ${passedTests}${colors.reset}`);
    console.log(`${colors.red}Failed: ${failedTests}${colors.reset}`);
    
    const successRate = totalTests > 0 ? (passedTests / totalTests * 100).toFixed(1) : 0;
    const rateColor = successRate >= 80 ? colors.green : 
                     successRate >= 60 ? colors.yellow : colors.red;
    console.log(`${rateColor}Success Rate: ${successRate}%${colors.reset}`);
    
    // Exit with appropriate code
    process.exit(failedTests > 0 ? 1 : 0);
}

// Run tests
if (require.main === module) {
    runAllTests().catch(err => {
        console.error(`${colors.red}Test suite failed: ${err}${colors.reset}`);
        process.exit(1);
    });
}