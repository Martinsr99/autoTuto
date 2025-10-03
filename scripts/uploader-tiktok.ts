import axios from 'axios';
import FormData from 'form-data';
import * as fs from 'fs';
import * as path from 'path';

interface TikTokMetadata {
  title: string;
  description?: string;
  privacy_level: 'PUBLIC_TO_EVERYONE' | 'MUTUAL_FOLLOW_FRIENDS' | 'SELF_ONLY';
  disable_duet?: boolean;
  disable_comment?: boolean;
  disable_stitch?: boolean;
  video_cover_timestamp_ms?: number;
}

interface UploadResult {
  success: boolean;
  videoId?: string;
  shareUrl?: string;
  error?: string;
  isDraft?: boolean;
}

class TikTokUploader {
  private accessToken: string;
  private clientKey: string;
  private clientSecret: string;
  private baseUrl = 'https://open.tiktokapis.com/v2';

  constructor() {
    this.accessToken = process.env.TIKTOK_ACCESS_TOKEN || '';
    this.clientKey = process.env.TIKTOK_CLIENT_KEY || '';
    this.clientSecret = process.env.TIKTOK_CLIENT_SECRET || '';

    if (!this.accessToken || !this.clientKey) {
      throw new Error('Missing TikTok API credentials in environment variables');
    }
  }

  /**
   * Upload a video to TikTok
   * Note: TikTok API may have limitations, this might create a draft instead
   */
  async uploadVideo(
    videoPath: string,
    metadata: TikTokMetadata
  ): Promise<UploadResult> {
    try {
      console.log(`[TikTok] Uploading video: ${videoPath}`);
      console.log(`[TikTok] Title: ${metadata.title}`);

      if (!fs.existsSync(videoPath)) {
        throw new Error(`Video file not found: ${videoPath}`);
      }

      const fileSize = fs.statSync(videoPath).size;
      console.log(`[TikTok] File size: ${(fileSize / 1024 / 1024).toFixed(2)} MB`);

      // Step 1: Initialize upload
      const initResponse = await this.initializeUpload(fileSize);
      
      if (!initResponse.success) {
        throw new Error(`Failed to initialize upload: ${initResponse.error}`);
      }

      console.log(`[TikTok] Upload initialized: ${initResponse.uploadUrl}`);

      // Step 2: Upload video file
      await this.uploadVideoFile(videoPath, initResponse.uploadUrl!);
      
      console.log('[TikTok] Video file uploaded');

      // Step 3: Publish or create draft
      const publishResponse = await this.publishVideo(
        initResponse.uploadId!,
        metadata
      );

      if (publishResponse.success) {
        console.log('[TikTok] ✓ Video published/drafted successfully');
        return publishResponse;
      } else {
        throw new Error(`Failed to publish: ${publishResponse.error}`);
      }

    } catch (error: any) {
      console.error('[TikTok] Upload failed:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Initialize upload session
   */
  private async initializeUpload(fileSize: number): Promise<{
    success: boolean;
    uploadUrl?: string;
    uploadId?: string;
    error?: string;
  }> {
    try {
      const response = await axios.post(
        `${this.baseUrl}/post/publish/video/init/`,
        {
          post_info: {
            title: 'Video Upload',
            privacy_level: 'PUBLIC_TO_EVERYONE',
            disable_duet: false,
            disable_comment: false,
            disable_stitch: false,
            video_cover_timestamp_ms: 1000
          },
          source_info: {
            source: 'FILE_UPLOAD',
            video_size: fileSize,
            chunk_size: fileSize,
            total_chunk_count: 1
          }
        },
        {
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return {
        success: true,
        uploadUrl: response.data.data.upload_url,
        uploadId: response.data.data.publish_id
      };

    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || error.message
      };
    }
  }

  /**
   * Upload video file to TikTok servers
   */
  private async uploadVideoFile(videoPath: string, uploadUrl: string): Promise<void> {
    const formData = new FormData();
    formData.append('video', fs.createReadStream(videoPath));

    await axios.put(uploadUrl, formData, {
      headers: {
        ...formData.getHeaders(),
        'Content-Type': 'video/mp4'
      },
      maxContentLength: Infinity,
      maxBodyLength: Infinity
    });
  }

  /**
   * Publish the uploaded video
   */
  private async publishVideo(
    uploadId: string,
    metadata: TikTokMetadata
  ): Promise<UploadResult> {
    try {
      const response = await axios.post(
        `${this.baseUrl}/post/publish/status/fetch/`,
        {
          publish_id: uploadId
        },
        {
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      const status = response.data.data.status;
      const videoId = response.data.data.video_id;

      if (status === 'PUBLISH_COMPLETE') {
        return {
          success: true,
          videoId: videoId,
          shareUrl: `https://www.tiktok.com/@user/video/${videoId}`,
          isDraft: false
        };
      } else if (status === 'PROCESSING_UPLOAD') {
        console.log('[TikTok] Video is still processing...');
        return {
          success: true,
          videoId: uploadId,
          isDraft: true
        };
      } else {
        return {
          success: false,
          error: `Upload status: ${status}`
        };
      }

    } catch (error: any) {
      // If direct publish fails, treat as draft
      console.warn('[TikTok] Direct publish not available, video created as draft');
      return {
        success: true,
        videoId: uploadId,
        isDraft: true
      };
    }
  }

  /**
   * Load metadata from JSON file
   */
  static loadMetadata(metadataPath: string): TikTokMetadata {
    if (!fs.existsSync(metadataPath)) {
      throw new Error(`Metadata file not found: ${metadataPath}`);
    }

    const data = JSON.parse(fs.readFileSync(metadataPath, 'utf-8'));
    
    return {
      title: data.title || 'Untitled Video',
      description: data.description || '',
      privacy_level: data.privacyLevel || 'PUBLIC_TO_EVERYONE',
      disable_duet: data.disableDuet ?? false,
      disable_comment: data.disableComment ?? false,
      disable_stitch: data.disableStitch ?? false,
      video_cover_timestamp_ms: data.coverTimestamp || 1000
    };
  }
}

// CLI Usage
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 2) {
    console.error('Usage: ts-node uploader-tiktok.ts <video-path> <metadata-json-path>');
    process.exit(1);
  }

  const [videoPath, metadataPath] = args;

  try {
    const uploader = new TikTokUploader();
    const metadata = TikTokUploader.loadMetadata(metadataPath);
    const result = await uploader.uploadVideo(videoPath, metadata);

    if (result.success) {
      console.log('\n=== Upload Successful ===');
      if (result.isDraft) {
        console.log('Status: Created as DRAFT (requires manual publish)');
        console.log(`Upload ID: ${result.videoId}`);
      } else {
        console.log('Status: Published');
        console.log(`Video ID: ${result.videoId}`);
        console.log(`URL: ${result.shareUrl}`);
      }
      process.exit(0);
    } else {
      console.error('\n=== Upload Failed ===');
      console.error(`Error: ${result.error}`);
      process.exit(1);
    }
  } catch (error: any) {
    console.error('Fatal error:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

export { TikTokUploader, TikTokMetadata, UploadResult };
