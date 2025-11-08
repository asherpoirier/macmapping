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

      console.log('Response received:', response.status, response.statusText);
      console.log('Response headers:', [...response.headers.entries()]);

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

      // Get the CSV text directly
      console.log('Getting response text...');
      const csvText = await response.text();
      console.log('CSV text length:', csvText.length, 'characters');
      console.log('First 100 chars:', csvText.substring(0, 100));
      
      if (!csvText || csvText.length === 0) {
        throw new Error('Received empty response from server');
      }
      
      // Create blob from text
      const blob = new Blob([csvText], { type: 'text/csv;charset=utf-8;' });
      console.log('Blob created:', blob.size, 'bytes');
      
      // Create download link
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'user_mac_mapping.csv');
      link.style.visibility = 'hidden';
      
      document.body.appendChild(link);
      console.log('Download link created and added to DOM');
      
      // Trigger download
      link.click();
      console.log('Download triggered');
      
      // Cleanup
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      console.log('Cleanup complete');

      setSuccess('✓ CSV file downloaded successfully! Check your Downloads folder.');
      setTimeout(() => setSuccess(null), 5000);
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
