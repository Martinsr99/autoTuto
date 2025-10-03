import { google } from 'googleapis';
import * as fs from 'fs';
import * as path from 'path';

interface VideoMetadata {
  title: string;
  description: string;
  tags: string[];
  categoryId: string;
  privacyStatus: 'public' | 'private' | 'unlisted';
  thumbnailPath?: string;
}

interface UploadResult {
  success: boolean;
  videoId?: string;
  url?: string;
  error?: string;
}

class YouTubeUploader {
  private youtube;
  private oauth2Client;

  constructor() {
    const clientId = process.env.YOUTUBE_CLIENT_ID;
    const clientSecret = process.env.YOUTUBE_CLIENT_SECRET;
    const refreshToken = process.env.YOUTUBE_REFRESH_TOKEN;

    if (!clientId || !clientSecret || !refreshToken) {
      throw new Error('Missing YouTube API credentials in environment variables');
    }

    this.oauth2Client = new google.auth.OAuth2(
      clientId,
      clientSecret,
      'http://localhost:3000/oauth2callback'
    );

    this.oauth2Client.setCredentials({
      refresh_token: refreshToken
    });

    this.youtube = google.youtube({
      version: 'v3',
      auth: this.oauth2Client
    });
  }

  /**
   * Upload a video to YouTube
   */
  async uploadVideo(
    videoPath: string,
    metadata: VideoMetadata
  ): Promise<UploadResult> {
    try {
      console.log(`[YouTube] Uploading video: ${videoPath}`);
      console.log(`[YouTube] Title: ${metadata.title}`);

      if (!fs.existsSync(videoPath)) {
        throw new Error(`Video file not found: ${videoPath}`);
      }

      const fileSize = fs.statSync(videoPath).size;
      console.log(`[YouTube] File size: ${(fileSize / 1024 / 1024).toFixed(2)} MB`);

      // Upload video
      const response = await this.youtube.videos.insert({
        part: ['snippet', 'status'],
        requestBody: {
          snippet: {
            title: metadata.title,
            description: metadata.description,
            tags: metadata.tags,
            categoryId: metadata.categoryId,
            defaultLanguage: 'es',
            defaultAudioLanguage: 'es'
          },
          status: {
            privacyStatus: metadata.privacyStatus,
            selfDeclaredMadeForKids: false
          }
        },
        media: {
          body: fs.createReadStream(videoPath)
        }
      });

      const videoId = response.data.id;
      const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;

      console.log(`[YouTube] ✓ Video uploaded successfully`);
      console.log(`[YouTube] Video ID: ${videoId}`);
      console.log(`[YouTube] URL: ${videoUrl}`);

      // Upload thumbnail if provided
      if (metadata.thumbnailPath && fs.existsSync(metadata.thumbnailPath)) {
        await this.uploadThumbnail(videoId!, metadata.thumbnailPath);
      }

      return {
        success: true,
        videoId: videoId!,
        url: videoUrl
      };

    } catch (error: any) {
      console.error('[YouTube] Upload failed:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Upload custom thumbnail
   */
  async uploadThumbnail(videoId: string, thumbnailPath: string): Promise<void> {
    try {
      console.log(`[YouTube] Uploading thumbnail: ${thumbnailPath}`);

      await this.youtube.thumbnails.set({
        videoId: videoId,
        media: {
          body: fs.createReadStream(thumbnailPath)
        }
      });

      console.log('[YouTube] ✓ Thumbnail uploaded successfully');
    } catch (error: any) {
      console.error('[YouTube] Thumbnail upload failed:', error.message);
    }
  }

  /**
   * Load metadata from JSON file
   */
  static loadMetadata(metadataPath: string): VideoMetadata {
    if (!fs.existsSync(metadataPath)) {
      throw new Error(`Metadata file not found: ${metadataPath}`);
    }

    const data = JSON.parse(fs.readFileSync(metadataPath, 'utf-8'));
    
    return {
      title: data.title || 'Untitled Video',
      description: data.description || '',
      tags: data.tags || [],
      categoryId: data.categoryId || '22', // 22 = People & Blogs
      privacyStatus: data.privacyStatus || 'public',
      thumbnailPath: data.thumbnailPath
    };
  }
}

// CLI Usage
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 2) {
    console.error('Usage: ts-node uploader-youtube.ts <video-path> <metadata-json-path>');
    process.exit(1);
  }

  const [videoPath, metadataPath] = args;

  try {
    const uploader = new YouTubeUploader();
    const metadata = YouTubeUploader.loadMetadata(metadataPath);
    const result = await uploader.uploadVideo(videoPath, metadata);

    if (result.success) {
      console.log('\n=== Upload Successful ===');
      console.log(`Video ID: ${result.videoId}`);
      console.log(`URL: ${result.url}`);
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

export { YouTubeUploader, VideoMetadata, UploadResult };
