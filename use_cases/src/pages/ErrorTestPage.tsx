import React, { useState } from 'react';
import { WebFListView } from '@openwebf/react-core-ui';

/**
 * Page to test JavaScript error handling and stack trace display in Dart
 */
export const ErrorTestPage: React.FC = () => {
  const [errorResult, setErrorResult] = useState<string>('');

  // Test 1: Simple error
  const throwSimpleError = () => {
    setErrorResult('');
    try {
      throw new Error('This is a simple test error');
    } catch (e) {
      setErrorResult(`Caught in JS: ${e instanceof Error ? e.message : String(e)}`);
    }
  };

  // Test 2: Uncaught error (will be caught by onJSError)
  const throwUncaughtError = () => {
    setErrorResult('Throwing uncaught error - check Dart console!');
    setTimeout(() => {
      throw new Error('This is an UNCAUGHT error - should appear in Dart console with stack trace');
    }, 100);
  };

  // Test 3: Error in nested function calls
  const level3Function = () => {
    throw new Error('Error from nested function call (level 3)');
  };

  const level2Function = () => {
    level3Function();
  };

  const level1Function = () => {
    level2Function();
  };

  const throwNestedError = () => {
    setErrorResult('Throwing error from nested calls - check Dart console!');
    setTimeout(() => {
      level1Function();
    }, 100);
  };

  // Test 4: TypeError
  const throwTypeError = () => {
    setErrorResult('Throwing TypeError - check Dart console!');
    setTimeout(() => {
      const obj: any = null;
      obj.someMethod(); // This will throw TypeError
    }, 100);
  };

  // Test 5: ReferenceError
  const throwReferenceError = () => {
    setErrorResult('Throwing ReferenceError - check Dart console!');
    setTimeout(() => {
      // @ts-ignore
      undefinedVariable.doSomething();
    }, 100);
  };

  // Test 6: Promise rejection
  const throwPromiseRejection = () => {
    setErrorResult('Throwing unhandled Promise rejection - check Dart console!');
    Promise.reject(new Error('Unhandled Promise rejection with stack trace'));
  };

  return (
    <div id="main" style={{ padding: '20px' }}>
      <WebFListView>
        <div style={{ padding: '20px' }}>
          <h1 style={{ fontSize: '24px', marginBottom: '20px', fontWeight: 'bold' }}>
            JavaScript Error Test Page
          </h1>

          <p style={{ marginBottom: '20px', color: '#666' }}>
            This page tests JavaScript error handling and stack trace display in Dart console.
            Each button will trigger a different type of error.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <button
              onClick={throwSimpleError}
              style={{
                padding: '12px 20px',
                backgroundColor: '#4CAF50',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '16px',
                cursor: 'pointer'
              }}
            >
              1. Throw Simple Error (Caught)
            </button>

            <button
              onClick={throwUncaughtError}
              style={{
                padding: '12px 20px',
                backgroundColor: '#f44336',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '16px',
                cursor: 'pointer'
              }}
            >
              2. Throw Uncaught Error
            </button>

            <button
              onClick={throwNestedError}
              style={{
                padding: '12px 20px',
                backgroundColor: '#ff9800',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '16px',
                cursor: 'pointer'
              }}
            >
              3. Throw Error from Nested Calls
            </button>

            <button
              onClick={throwTypeError}
              style={{
                padding: '12px 20px',
                backgroundColor: '#9c27b0',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '16px',
                cursor: 'pointer'
              }}
            >
              4. Throw TypeError
            </button>

            <button
              onClick={throwReferenceError}
              style={{
                padding: '12px 20px',
                backgroundColor: '#2196F3',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '16px',
                cursor: 'pointer'
              }}
            >
              5. Throw ReferenceError
            </button>

            <button
              onClick={throwPromiseRejection}
              style={{
                padding: '12px 20px',
                backgroundColor: '#607d8b',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '16px',
                cursor: 'pointer'
              }}
            >
              6. Unhandled Promise Rejection
            </button>
          </div>

          {errorResult && (
            <div
              style={{
                marginTop: '20px',
                padding: '16px',
                backgroundColor: '#fff3cd',
                border: '1px solid #ffc107',
                borderRadius: '8px',
                color: '#856404'
              }}
            >
              <strong>Result:</strong>
              <pre style={{ marginTop: '8px', whiteSpace: 'pre-wrap' }}>{errorResult}</pre>
            </div>
          )}

          <div
            style={{
              marginTop: '24px',
              padding: '16px',
              backgroundColor: '#e3f2fd',
              border: '1px solid #2196F3',
              borderRadius: '8px',
              color: '#0d47a1'
            }}
          >
            <strong>💡 Instructions:</strong>
            <ul style={{ marginTop: '8px', paddingLeft: '20px' }}>
              <li>Click buttons 2-6 to trigger uncaught errors</li>
              <li>Check your Dart/Flutter console/terminal</li>
              <li>You should see the full JavaScript error stack trace</li>
              <li>Look for lines starting with "❌ JavaScript Error"</li>
            </ul>
          </div>
        </div>
      </WebFListView>
    </div>
  );
};
