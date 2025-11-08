import React, { useState } from 'react';
import './App.css';

function App() {
  const [oldFile, setOldFile] = useState(null);
  const [magsFile, setMagsFile] = useState(null);
  const [newFile, setNewFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [preview, setPreview] = useState(null);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  const handleFileChange = (setter) => (e) => {
    const file = e.target.files[0];
    if (file) {
      // Accept CSV files regardless of MIME type (some systems report different types)
      if (file.name.endsWith('.csv') || file.type === 'text/csv' || file.type === 'application/vnd.ms-excel') {
        setter(file);
        setError(null);
        console.log('File selected:', file.name, file.size, 'bytes');
      } else {
        setError('Please select a CSV file (.csv extension)');
      }
    }
  };

  const handlePreview = async () => {
    if (!oldFile || !magsFile || !newFile) {
      setError('Please upload all three CSV files');
      return;
    }

    setLoading(true);
    setError(null);
    setPreview(null);

    try {
      const formData = new FormData();
      formData.append('old_file', oldFile);
      formData.append('mags_file', magsFile);
      formData.append('new_file', newFile);

      const response = await fetch(`${process.env.REACT_APP_BACKEND_URL}/api/preview`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Failed to preview mapping');
      }

      const data = await response.json();
      setPreview(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleGenerate = async () => {
    if (!oldFile || !magsFile || !newFile) {
      setError('Please upload all three CSV files');
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      console.log('Starting file generation...');
      
      const formData = new FormData();
      formData.append('old_file', oldFile);
      formData.append('mags_file', magsFile);
      formData.append('new_file', newFile);

      const apiUrl = `${process.env.REACT_APP_BACKEND_URL}/api/process-files`;
      console.log('Sending request to:', apiUrl);
      
      const response = await fetch(apiUrl, {
        method: 'POST',
        body: formData,
      });

      console.log('Response received:', response.status);

      if (!response.ok) {
        let errorMessage = 'Failed to generate mapping';
        try {
          const errorData = await response.json();
          errorMessage = errorData.detail || errorMessage;
        } catch (e) {
          const text = await response.text();
          errorMessage = text || errorMessage;
        }
        throw new Error(errorMessage);
      }

      // Get the CSV text
      const csvText = await response.text();
      console.log('Received CSV, length:', csvText.length);
      
      if (!csvText || csvText.length === 0) {
        throw new Error('Received empty response from server');
      }
      
      // Since download is blocked in sandbox, show the CSV in a new window with copy/download instructions
      console.log('Opening CSV in new window...');
      
      // Create an HTML page with the CSV content that user can download
      const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <title>User MAC Mapping - Download</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 1200px;
      margin: 20px auto;
      padding: 20px;
      background: #f5f5f5;
    }
    .container {
      background: white;
      padding: 30px;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    h1 { color: #667eea; }
    .instructions {
      background: #e6f3ff;
      padding: 15px;
      border-radius: 5px;
      margin: 20px 0;
      border-left: 4px solid #667eea;
    }
    .csv-content {
      background: #f9f9f9;
      border: 1px solid #ddd;
      padding: 15px;
      border-radius: 5px;
      overflow-x: auto;
      font-family: monospace;
      font-size: 12px;
      white-space: pre;
      max-height: 500px;
      overflow-y: auto;
    }
    button {
      background: #667eea;
      color: white;
      padding: 12px 24px;
      border: none;
      border-radius: 5px;
      cursor: pointer;
      font-size: 16px;
      margin: 10px 5px;
    }
    button:hover { background: #5568d3; }
    .success { color: green; margin: 10px 0; font-weight: bold; }
  </style>
</head>
<body>
  <div class="container">
    <h1>📊 User-MAC Address Mapping</h1>
    
    <div class="instructions">
      <h3>📥 Download Instructions:</h3>
      <ol>
        <li><strong>Method 1 (Recommended):</strong> Click the "Download CSV" button below</li>
        <li><strong>Method 2:</strong> Right-click anywhere on this page → "Save Page As" → Save as "user_mac_mapping.csv"</li>
        <li><strong>Method 3:</strong> Click "Copy to Clipboard", then paste into a text editor and save as .csv</li>
      </ol>
    </div>
    
    <div>
      <button onclick="downloadCSV()">📥 Download CSV File</button>
      <button onclick="copyToClipboard()">📋 Copy to Clipboard</button>
    </div>
    
    <div id="status"></div>
    
    <h3>CSV Content Preview:</h3>
    <div class="csv-content" id="csvContent">${csvText.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</div>
  </div>

  <script>
    const csvData = ${JSON.stringify(csvText)};
    
    function downloadCSV() {
      try {
        const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'user_mac_mapping.csv';
        a.click();
        URL.revokeObjectURL(url);
        document.getElementById('status').innerHTML = '<div class="success">✓ Download started! Check your Downloads folder.</div>';
      } catch (err) {
        document.getElementById('status').innerHTML = '<div style="color: red;">✗ Error: ' + err.message + '. Please use Method 2 or 3.</div>';
      }
    }
    
    function copyToClipboard() {
      navigator.clipboard.writeText(csvData).then(() => {
        document.getElementById('status').innerHTML = '<div class="success">✓ CSV content copied to clipboard! Paste it into a text editor and save as .csv</div>';
      }).catch((err) => {
        // Fallback
        const textarea = document.createElement('textarea');
        textarea.value = csvData;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        document.getElementById('status').innerHTML = '<div class="success">✓ CSV content copied to clipboard!</div>';
      });
    }
  </script>
</body>
</html>`;
      
      // Open in new window
      const newWindow = window.open('', '_blank');
      if (newWindow) {
        newWindow.document.write(htmlContent);
        newWindow.document.close();
        console.log('✓ CSV opened in new window');
        setSuccess('✓ CSV opened in new tab! Use the download button on that page or save the page as user_mac_mapping.csv');
      } else {
        throw new Error('Pop-up blocked. Please allow pop-ups for this site.');
      }
      
      setTimeout(() => setSuccess(null), 10000);
      
    } catch (err) {
      console.error('Error during file generation:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setOldFile(null);
    setMagsFile(null);
    setNewFile(null);
    setPreview(null);
    setError(null);
    setSuccess(null);
  };

  return (
    <div className="App">
      <div className="container">
        <header className="header">
          <h1 className="title">User-MAC Address Mapper</h1>
          <p className="subtitle">Upload CSV files to generate user ID to MAC address mappings</p>
        </header>

        <div className="upload-section">
          <div className="file-upload-grid">
            <div className="file-upload-card">
              <label className="file-label">
                <span className="file-icon">📄</span>
                <span className="file-title">Old Users CSV</span>
                <input
                  type="file"
                  accept=".csv"
                  onChange={handleFileChange(setOldFile)}
                  className="file-input"
                />
                {oldFile && <span className="file-name">✓ {oldFile.name}</span>}
              </label>
            </div>

            <div className="file-upload-card">
              <label className="file-label">
                <span className="file-icon">🔌</span>
                <span className="file-title">MACs CSV</span>
                <input
                  type="file"
                  accept=".csv"
                  onChange={handleFileChange(setMagsFile)}
                  className="file-input"
                />
                {magsFile && <span className="file-name">✓ {magsFile.name}</span>}
              </label>
            </div>

            <div className="file-upload-card">
              <label className="file-label">
                <span className="file-icon">📋</span>
                <span className="file-title">New Users CSV</span>
                <input
                  type="file"
                  accept=".csv"
                  onChange={handleFileChange(setNewFile)}
                  className="file-input"
                />
                {newFile && <span className="file-name">✓ {newFile.name}</span>}
              </label>
            </div>
          </div>

          {error && (
            <div className="error-message">
              <span className="error-icon">⚠️</span>
              {error}
            </div>
          )}

          {success && (
            <div className="success-message">
              <span className="success-icon">✓</span>
              {success}
            </div>
          )}

          <div className="button-group">
            <button
              onClick={handlePreview}
              disabled={loading || !oldFile || !magsFile || !newFile}
              className="btn btn-secondary"
            >
              {loading ? 'Processing...' : '👁️ Preview Mapping'}
            </button>
            <button
              onClick={handleGenerate}
              disabled={loading || !oldFile || !magsFile || !newFile}
              className="btn btn-primary"
            >
              {loading ? 'Generating...' : '⬇️ Generate & Download CSV'}
            </button>
            <button
              onClick={handleReset}
              disabled={loading}
              className="btn btn-outline"
            >
              🔄 Reset
            </button>
          </div>
        </div>

        {preview && (
          <div className="preview-section">
            <h2 className="preview-title">Mapping Preview</h2>
            
            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-value">{preview.total_mappings}</div>
                <div className="stat-label">Total Mappings</div>
              </div>
              <div className="stat-card">
                <div className="stat-value">{preview.with_mac}</div>
                <div className="stat-label">With MAC Address</div>
              </div>
              <div className="stat-card">
                <div className="stat-value">{preview.without_mac}</div>
                <div className="stat-label">Without MAC Address</div>
              </div>
            </div>

            <div className="sample-table-container">
              <h3 className="sample-title">Sample Data (First 10 Rows)</h3>
              <div className="table-wrapper">
                <table className="sample-table">
                  <thead>
                    <tr>
                      <th>Old User ID</th>
                      <th>MAC Address</th>
                      <th>New User ID</th>
                      <th>Username</th>
                    </tr>
                  </thead>
                  <tbody>
                    {preview.sample.map((row, index) => (
                      <tr key={index}>
                        <td>{row.old_user_id}</td>
                        <td>
                          <code className={row.mac_address === 'N/A' ? 'mac-na' : 'mac-address'}>
                            {row.mac_address}
                          </code>
                        </td>
                        <td>{row.new_user_id}</td>
                        <td className="username">{row.username}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        <footer className="footer">
          <div className="info-box">
            <h3>How It Works</h3>
            <ol>
              <li>Upload your <strong>Old Users CSV</strong> (contains original user IDs)</li>
              <li>Upload your <strong>MACs CSV</strong> (contains MAC addresses linked to user IDs)</li>
              <li>Upload your <strong>New Users CSV</strong> (contains new user IDs)</li>
              <li>Click <strong>Preview</strong> to see statistics and sample data</li>
              <li>Click <strong>Generate & Download</strong> to create your mapping CSV</li>
            </ol>
          </div>
        </footer>
      </div>
    </div>
  );
}

export default App;
