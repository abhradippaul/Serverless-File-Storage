import React, { useState, useEffect, useRef } from 'react';
import {
  UploadCloud,
  File,
  FileText,
  Image as ImageIcon,
  Music,
  Video,
  Archive,
  Code,
  Download,
  Trash2,
  ExternalLink,
  Copy,
  Check,
  AlertCircle,
  RefreshCw,
  HardDrive,
  User,
  Search,
} from 'lucide-react';
import type { UploadedFile, S3ConfigResponse } from './types';
import {
  getOrCreateUserId,
  fetchUserFiles,
  getPresignedUploadUrl,
  uploadToS3Direct,
  getPresignedDownloadUrl,
  deleteS3File,
  fetchServerConfig,
} from './services/storage';
import './App.css';

export default function App() {
  const [userId] = useState<string>(() => getOrCreateUserId());
  const [files, setFiles] = useState<UploadedFile[]>([]);
  const [isFilesLoading, setIsFilesLoading] = useState(true);
  const [filesError, setFilesError] = useState<string | null>(null);
  const [serverConfig, setServerConfig] = useState<S3ConfigResponse | null>(null);
  const [, setIsConfigLoading] = useState(true);

  // Upload state
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [uploadSuccess, setUploadSuccess] = useState<string | null>(null);

  // Search filter
  const [searchQuery, setSearchQuery] = useState('');
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);

  const loadFilesFromBackend = async () => {
    setIsFilesLoading(true);
    setFilesError(null);
    try {
      const remoteFiles = await fetchUserFiles(userId);
      setFiles(remoteFiles);
    } catch (err: any) {
      console.error('Failed to load files from backend:', err);
      setFilesError(err.message || 'Could not load uploaded files');
    } finally {
      setIsFilesLoading(false);
    }
  };

  // Load files from DynamoDB via backend on mount
  useEffect(() => {
    loadFilesFromBackend();
  }, [userId]);

  // Load backend / S3 config on mount
  useEffect(() => {
    fetchServerConfig()
      .then((cfg) => setServerConfig(cfg))
      .catch((err) => console.warn('Could not load backend config:', err))
      .finally(() => setIsConfigLoading(false));
  }, []);

  // Format file size
  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
  };

  // Get matching icon for file type
  const getFileIcon = (fileName: string, mimeType: string) => {
    const ext = fileName.split('.').pop()?.toLowerCase() || '';
    if (mimeType.startsWith('image/') || ['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp'].includes(ext)) {
      return <ImageIcon className="file-type-icon icon-image" />;
    }
    if (mimeType.startsWith('video/') || ['mp4', 'mkv', 'webm', 'mov'].includes(ext)) {
      return <Video className="file-type-icon icon-video" />;
    }
    if (mimeType.startsWith('audio/') || ['mp3', 'wav', 'ogg', 'aac'].includes(ext)) {
      return <Music className="file-type-icon icon-audio" />;
    }
    if (['zip', 'tar', 'gz', 'rar', '7z'].includes(ext)) {
      return <Archive className="file-type-icon icon-archive" />;
    }
    if (['json', 'js', 'ts', 'jsx', 'tsx', 'html', 'css', 'py', 'java', 'tf'].includes(ext)) {
      return <Code className="file-type-icon icon-code" />;
    }
    if (['pdf', 'doc', 'docx', 'txt', 'md'].includes(ext)) {
      return <FileText className="file-type-icon icon-doc" />;
    }
    return <File className="file-type-icon" />;
  };

  // Handle Drag & Drop
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      setSelectedFile(e.dataTransfer.files[0]);
      setUploadError(null);
      setUploadSuccess(null);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setSelectedFile(e.target.files[0]);
      setUploadError(null);
      setUploadSuccess(null);
    }
  };

  // Handle File Upload Flow
  const handleUpload = async () => {
    if (!selectedFile) return;

    setIsUploading(true);
    setUploadProgress(0);
    setUploadError(null);
    setUploadSuccess(null);

    const fileToUpload = selectedFile;
    const tempId = `file_${Date.now()}`;

    // Add tentative entry to files
    const pendingFileRecord: UploadedFile = {
      id: tempId,
      name: fileToUpload.name,
      size: fileToUpload.size,
      type: fileToUpload.type || 'application/octet-stream',
      key: 'Generating URL...',
      uploadedAt: new Date().toISOString(),
      status: 'uploading',
      progress: 0,
    };

    setFiles((prev) => [pendingFileRecord, ...prev]);

    try {
      // 1. Get Presigned URL from Backend
      const { uploadUrl, key } = await getPresignedUploadUrl(
        fileToUpload.name,
        fileToUpload.type,
        userId
      );

      // Update file entry with S3 key
      setFiles((prev) =>
        prev.map((item) => (item.id === tempId ? { ...item, key } : item))
      );

      // 2. Direct upload to S3 via Presigned PUT URL
      await uploadToS3Direct(uploadUrl, fileToUpload, (percent) => {
        setUploadProgress(percent);
        setFiles((prev) =>
          prev.map((item) =>
            item.id === tempId ? { ...item, progress: percent } : item
          )
        );
      });

      // 3. Mark as completed
      setFiles((prev) =>
        prev.map((item) =>
          item.id === tempId
            ? { ...item, status: 'completed', progress: 100 }
            : item
        )
      );

      setUploadSuccess(`"${fileToUpload.name}" uploaded to S3 successfully!`);
      setSelectedFile(null);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    } catch (err: any) {
      const errMsg = err.message || 'Failed to upload file to S3';
      setUploadError(errMsg);
      setFiles((prev) =>
        prev.map((item) =>
          item.id === tempId
            ? { ...item, status: 'failed', error: errMsg }
            : item
        )
      );
    } finally {
      setIsUploading(false);
    }
  };

  // Handle Download / Open File
  const handleDownload = async (fileItem: UploadedFile, openInNewTab = false) => {
    try {
      const { downloadUrl } = await getPresignedDownloadUrl(fileItem.key, fileItem.name);
      if (openInNewTab) {
        window.open(downloadUrl, '_blank');
      } else {
        const link = document.createElement('a');
        link.href = downloadUrl;
        link.download = fileItem.name;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      }
    } catch (err: any) {
      alert(`Could not download file: ${err.message || err}`);
    }
  };

  // Handle Delete File
  const handleDelete = async (fileItem: UploadedFile) => {
    if (!window.confirm(`Delete "${fileItem.name}" from S3 and your history?`)) {
      return;
    }

    try {
      await deleteS3File(fileItem.key);
      setFiles((prev) => prev.filter((item) => item.id !== fileItem.id));
    } catch (err: any) {
      console.warn('Could not delete from S3:', err);
      // Even if S3 deletion fails (e.g. file already gone), allow removing from local view
      if (window.confirm('Could not delete from S3 directly. Remove from local list anyway?')) {
        setFiles((prev) => prev.filter((item) => item.id !== fileItem.id));
      }
    }
  };

  // Copy Key to Clipboard
  const handleCopyKey = (key: string) => {
    navigator.clipboard.writeText(key);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  const filteredFiles = files.filter((f) =>
    f.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    f.key.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="app-container">
      {/* Header */}
      <header className="app-header">
        <div className="header-left">
          <div className="logo-badge">
            <HardDrive className="logo-icon" />
          </div>
          <div>
            <h1 className="app-title">Serverless File Storage</h1>
            <p className="app-subtitle">Direct client-to-S3 uploads with presigned URLs</p>
          </div>
        </div>

        <div className="header-right">
          <div className="badge session-badge" title="Persistent anonymous session ID">
            <User className="badge-icon" />
            <span>Session: <strong>{userId}</strong></span>
          </div>
          {serverConfig && (
            <div className="badge bucket-badge" title={`S3 Bucket: ${serverConfig.bucket} (${serverConfig.region})`}>
              <HardDrive className="badge-icon" />
              <span>{serverConfig.bucket}</span>
            </div>
          )}
        </div>
      </header>

      {/* Main Content Grid */}
      <main className="main-content">
        {/* Upload Card */}
        <section className="card upload-card">
          <div className="card-header">
            <h2>Upload File to S3</h2>
            <p className="card-description">
              Uploads securely bypass the web server and go straight to Amazon S3 via presigned PUT URLs.
            </p>
          </div>

          <div
            className={`dropzone ${isDragging ? 'dropzone-active' : ''} ${selectedFile ? 'has-file' : ''}`}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            onClick={() => fileInputRef.current?.click()}
          >
            <input
              type="file"
              ref={fileInputRef}
              onChange={handleFileSelect}
              style={{ display: 'none' }}
            />
            <UploadCloud className="upload-icon" />
            {selectedFile ? (
              <div className="selected-file-info">
                <span className="file-name">{selectedFile.name}</span>
                <span className="file-size">{formatBytes(selectedFile.size)}</span>
              </div>
            ) : (
              <div className="dropzone-text">
                <p className="primary-text">Click to browse or drag and drop your file here</p>
                <p className="secondary-text">Any file format supported</p>
              </div>
            )}
          </div>

          {selectedFile && !isUploading && (
            <div className="upload-actions">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => {
                  setSelectedFile(null);
                  if (fileInputRef.current) fileInputRef.current.value = '';
                }}
              >
                Cancel
              </button>
              <button
                type="button"
                className="btn btn-primary"
                onClick={handleUpload}
              >
                Upload to S3
              </button>
            </div>
          )}

          {isUploading && (
            <div className="progress-section">
              <div className="progress-labels">
                <span>Uploading directly to S3...</span>
                <span>{uploadProgress}%</span>
              </div>
              <div className="progress-track">
                <div
                  className="progress-bar"
                  style={{ width: `${uploadProgress}%` }}
                />
              </div>
            </div>
          )}

          {uploadSuccess && (
            <div className="alert alert-success">
              <Check className="alert-icon" />
              <span>{uploadSuccess}</span>
            </div>
          )}

          {uploadError && (
            <div className="alert alert-error">
              <AlertCircle className="alert-icon" />
              <div>
                <strong>Upload Error:</strong> {uploadError}
              </div>
            </div>
          )}
        </section>

        {/* Upload History / Persistent Files List */}
        <section className="card list-card">
          <div className="list-header">
            <div className="list-title-wrap">
              <h2>Your Uploads</h2>
              <span className="count-badge">{files.length}</span>
            </div>
            <div className="list-controls">
              {files.length > 0 && (
                <div className="search-wrap">
                  <Search className="search-icon" />
                  <input
                    type="text"
                    placeholder="Search files..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="search-input"
                  />
                </div>
              )}
              <button
                type="button"
                className="btn btn-subtle"
                onClick={loadFilesFromBackend}
                disabled={isFilesLoading}
                title="Refresh files from DynamoDB"
              >
                <RefreshCw className={`mini-icon ${isFilesLoading ? 'spin-icon' : ''}`} /> Refresh
              </button>
            </div>
          </div>

          <p className="card-description">
            Your uploaded files are fetched directly from the backend via DynamoDB.
          </p>

          {filesError && (
            <div className="alert alert-error">
              <AlertCircle className="alert-icon" />
              <div>
                <strong>Load Error:</strong> {filesError}
              </div>
            </div>
          )}

          {isFilesLoading && files.length === 0 ? (
            <div className="empty-state">
              <RefreshCw className="empty-icon spin-icon" />
              <h3>Loading files...</h3>
              <p>Fetching your uploaded items from DynamoDB.</p>
            </div>
          ) : files.length === 0 ? (
            <div className="empty-state">
              <HardDrive className="empty-icon" />
              <h3>No files uploaded yet</h3>
              <p>Upload a file using the form above. Once processed, it will appear here from DynamoDB.</p>
            </div>
          ) : filteredFiles.length === 0 ? (
            <div className="empty-state">
              <Search className="empty-icon" />
              <h3>No matching files found</h3>
              <p>Try searching for a different file name.</p>
            </div>
          ) : (
            <div className="files-list">
              {filteredFiles.map((file) => (
                <div key={file.id} className="file-item">
                  <div className="file-item-left">
                    {getFileIcon(file.name, file.type)}
                    <div className="file-meta">
                      <div className="file-name-row">
                        <span className="file-item-name" title={file.name}>
                          {file.name}
                        </span>
                        {file.status === 'completed' && (
                          <span className="status-tag status-success">Uploaded</span>
                        )}
                        {file.status === 'uploading' && (
                          <span className="status-tag status-pending">
                            <RefreshCw className="spin-icon" /> {file.progress || 0}%
                          </span>
                        )}
                        {file.status === 'failed' && (
                          <span className="status-tag status-failed">Failed</span>
                        )}
                      </div>
                      <div className="file-details-row">
                        <span>{formatBytes(file.size)}</span>
                        <span className="dot">•</span>
                        <span>{new Date(file.uploadedAt).toLocaleString()}</span>
                        <span className="dot">•</span>
                        <button
                          type="button"
                          className="key-link"
                          onClick={() => handleCopyKey(file.key)}
                          title={`Copy S3 Key: ${file.key}`}
                        >
                          {copiedKey === file.key ? (
                            <>
                              <Check className="mini-icon text-success" /> Copied!
                            </>
                          ) : (
                            <>
                              <Copy className="mini-icon" /> {file.key.split('/').pop()}
                            </>
                          )}
                        </button>
                      </div>
                    </div>
                  </div>

                  <div className="file-item-actions">
                    {file.status === 'completed' && (
                      <>
                        <button
                          type="button"
                          className="action-btn"
                          title="Open in new tab"
                          onClick={() => handleDownload(file, true)}
                        >
                          <ExternalLink className="action-icon" />
                        </button>
                        <button
                          type="button"
                          className="action-btn"
                          title="Download file"
                          onClick={() => handleDownload(file, false)}
                        >
                          <Download className="action-icon" />
                        </button>
                      </>
                    )}
                    <button
                      type="button"
                      className="action-btn action-btn-danger"
                      title="Delete file"
                      onClick={() => handleDelete(file)}
                    >
                      <Trash2 className="action-icon" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>
      </main>

      {/* Footer Info */}
      <footer className="app-footer">
        <span>No login required • File metadata stored in DynamoDB • Direct AWS S3 presigned transfers</span>
      </footer>
    </div>
  );
}
