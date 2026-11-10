import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiStyleJob, AiJobStatus, AiVariationItem } from '../../entities/ai-style-job.entity';
import { AiSavedLook } from '../../entities/ai-saved-look.entity';
import { GenerateStyleDto } from './dto/generate-style.dto';
import { SaveLookDto } from './dto/save-look.dto';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class AiStyleService {
  private readonly logger = new Logger(AiStyleService.name);
  private readonly aiServiceUrl = process.env.AI_STYLE_SERVICE_URL || 'http://127.0.0.1:8000';
  private readonly baseUploadDir = path.resolve(process.cwd(), 'uploads/ai-styles');

  constructor(
    @InjectRepository(AiStyleJob)
    private readonly jobRepository: Repository<AiStyleJob>,
    @InjectRepository(AiSavedLook)
    private readonly lookRepository: Repository<AiSavedLook>,
  ) {
    this.ensureUploadDirs();
  }

  private ensureUploadDirs() {
    try {
      const originals = path.join(this.baseUploadDir, 'originals');
      const generated = path.join(this.baseUploadDir, 'generated');
      if (!fs.existsSync(originals)) fs.mkdirSync(originals, { recursive: true });
      if (!fs.existsSync(generated)) fs.mkdirSync(generated, { recursive: true });
    } catch (err) {
      this.logger.error('Failed to create AI style upload dirs', err);
    }
  }

  private unlinkSafe(relOrAbsUrl?: string) {
    if (!relOrAbsUrl) return;
    try {
      const rel = relOrAbsUrl.replace(/^\/+/, '');
      const fullPath = path.resolve(process.cwd(), rel);
      if (fullPath.startsWith(this.baseUploadDir) && fs.existsSync(fullPath)) {
        fs.unlinkSync(fullPath);
      }
    } catch (e) {
      this.logger.warn(`Failed to unlink file ${relOrAbsUrl}: ${e}`);
    }
  }

  getStyleOptions() {
    return {
      hairStyles: [
        { id: 'classic_taper', name: 'Classic Taper', description: 'Balanced low taper with scissor-textured top' },
        { id: 'textured_crop', name: 'Textured Crop', description: 'Modern crop with point-cut top and mid-low taper' },
        { id: 'classic_side_part', name: 'Classic Side Part', description: 'Refined side part with structured medium top' },
        { id: 'modern_quiff', name: 'Modern Quiff', description: 'Lifted front quiff with tapered temples' },
        { id: 'buzz_cut', name: 'Crew / Buzz Cut', description: 'Athletic graduated crew cut with tight taper' },
        { id: 'textured_fringe', name: 'Textured Fringe', description: 'Forward-swept layered fringe with low taper' },
        { id: 'ivy_league', name: 'Ivy League Taper', description: 'Smart-casual short side-swept taper' },
        { id: 'medium_length', name: 'Layered Medium Flow', description: 'Scissor-layered medium flow embracing natural wave' },
        { id: 'fade', name: 'High Skin Fade', description: 'High-contrast skin fade with buzzed top' },
        { id: 'curly_style', name: 'Structured Pompadour', description: 'Swept-back volume on top with clean temples' },
      ],
      beardStyles: [
        { id: 'clean_shaven', name: 'Clean Shaven', description: 'Smooth, hair-free jawline and upper lip' },
        { id: 'stubble', name: 'Designer Stubble', description: '2–3 mm refined designer stubble with neat neckline' },
        { id: 'short_beard', name: 'Short Boxed Beard', description: '4–6 mm manicured short boxed beard' },
        { id: 'full_beard', name: 'Well-Groomed Beard', description: '6–8 mm sculpted medium beard with crisp lines' },
        { id: 'goatee', name: 'Tailored Goatee', description: '5–7 mm circle goatee with clean-shaven cheeks' },
      ],
      preferenceOptions: {
        maintenanceLevels: [
          { id: 'any', label: 'Any Maintenance' },
          { id: 'low', label: 'Low Maintenance' },
          { id: 'medium', label: 'Medium Maintenance' },
          { id: 'high', label: 'High Styling Effort' },
        ],
        styleVibes: [
          { id: 'any', label: 'All Vibes' },
          { id: 'professional', label: 'Professional / Executive' },
          { id: 'modern', label: 'Modern & Trendy' },
          { id: 'casual', label: 'Casual Everyday' },
          { id: 'classic', label: 'Timeless Classic' },
        ],
        hairLengthPrefs: [
          { id: 'any', label: 'Keep Flexible' },
          { id: 'short', label: 'Go Shorter / Taper' },
          { id: 'medium', label: 'Medium Structured' },
          { id: 'long', label: 'Keep Volume / Flow' },
        ],
        beardPrefs: [
          { id: 'any', label: 'Recommend Best' },
          { id: 'clean_shaven', label: 'Clean Shaven' },
          { id: 'stubble', label: 'Light / Heavy Stubble' },
          { id: 'short_beard', label: 'Short Boxed Beard' },
          { id: 'full_beard', label: 'Full Groomed Beard' },
          { id: 'goatee', label: 'Goatee' },
        ],
      },
      hairColors: [
        { id: 'natural_black', name: 'Natural Black', hex: '#1C1C1C' },
        { id: 'dark_brown', name: 'Dark Brown', hex: '#3B2F2F' },
        { id: 'chestnut', name: 'Chestnut Auburn', hex: '#633A26' },
        { id: 'silver_grey', name: 'Salt & Pepper Grey', hex: '#A8A9AD' },
      ],
    };
  }

  async checkHealth() {
    try {
      const response = await fetch(`${this.aiServiceUrl}/api/v1/health`, { signal: AbortSignal.timeout(3000) });
      const data = await response.json();
      return {
        online: true,
        aiService: data,
      };
    } catch (err: any) {
      return {
        online: false,
        message: 'Local AI Style Service is currently offline or loading weights.',
        details: err.message,
      };
    }
  }

  async analyzePhoto(file?: any, imageBase64?: string): Promise<any> {
    let imageBuffer: Buffer;
    if (file && file.buffer) {
      imageBuffer = file.buffer;
    } else if (imageBase64) {
      const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
      imageBuffer = Buffer.from(base64Data, 'base64');
    } else {
      throw new BadRequestException('An image file or imageBase64 is required for analysis.');
    }

    const blob = new Blob([new Uint8Array(imageBuffer)], { type: 'image/jpeg' });
    const formData = new globalThis.FormData();
    formData.append('image', blob, 'photo.jpg');

    const res = await fetch(`${this.aiServiceUrl}/api/v1/analyze`, {
      method: 'POST',
      body: formData,
      signal: AbortSignal.timeout(30000),
    });

    if (!res.ok) {
      const errText = await res.text();
      let errorDetail = errText;
      try {
        const parsed = JSON.parse(errText);
        if (parsed.detail) errorDetail = parsed.detail;
      } catch (_) {}
      throw new BadRequestException(errorDetail);
    }

    return await res.json();
  }

  async generateStyle(
    customerId: string,
    dto: GenerateStyleDto,
    file?: any,
  ): Promise<any> {
    if (!dto.consentGiven) {
      throw new BadRequestException('Explicit user consent is mandatory for facial processing.');
    }

    let originalFilename: string;
    let originalLocalPath: string;
    const timestamp = Date.now();

    if (file) {
      const ext = path.extname(file.originalname) || '.jpg';
      originalFilename = `orig_${timestamp}_${Math.random().toString(36).substring(7)}${ext}`;
      originalLocalPath = path.join(this.baseUploadDir, 'originals', originalFilename);
      fs.writeFileSync(originalLocalPath, file.buffer);
    } else if (dto.imageBase64) {
      const base64Data = dto.imageBase64.replace(/^data:image\/\w+;base64,/, '');
      originalFilename = `orig_${timestamp}_${Math.random().toString(36).substring(7)}.jpg`;
      originalLocalPath = path.join(this.baseUploadDir, 'originals', originalFilename);
      fs.writeFileSync(originalLocalPath, Buffer.from(base64Data, 'base64'));
    } else {
      throw new BadRequestException('An original photo (file upload or imageBase64) is required.');
    }

    const originalImageUrl = `/uploads/ai-styles/originals/${originalFilename}`;
    const targetCount = Math.max(1, Math.min(6, dto.variationsCount || 6));

    const preferences = {
      maintenance_level: dto.maintenanceLevel || 'any',
      style_vibe: dto.styleVibe || 'any',
      hair_length_pref: dto.hairLengthPref || 'any',
      beard_pref: dto.beardPref || 'any',
      hair_style: dto.hairStyle,
      beard_style: dto.beardStyle,
      hair_color: dto.hairColor,
      beard_color: dto.beardColor,
    };

    const job = this.jobRepository.create({
      customer_id: customerId,
      original_image_url: originalImageUrl,
      hair_style: dto.hairStyle || 'dynamic_personalized',
      beard_style: dto.beardStyle || 'dynamic_personalized',
      hair_color: dto.hairColor,
      beard_color: dto.beardColor,
      variations_count: targetCount,
      completed_variations: 0,
      progress_stage: 'ANALYZING',
      preferences,
      status: AiJobStatus.PROCESSING,
      variations: [],
    });
    const savedJob = await this.jobRepository.save(job);

    if (dto.async) {
      // Run generation asynchronously in background; caller polls GET /style-studio/generations/:id
      this.executeGenerationJob(savedJob.id, originalLocalPath, dto, preferences, targetCount).catch((err) => {
        this.logger.error(`Background generation worker failed unexpectedly for job ${savedJob.id}: ${err.message}`);
      });
      return savedJob;
    }

    // Synchronous execution fallback
    return await this.executeGenerationJob(savedJob.id, originalLocalPath, dto, preferences, targetCount);
  }

  async executeGenerationJob(
    jobId: string,
    originalLocalPath: string,
    dto: GenerateStyleDto,
    preferences: any,
    targetCount: number,
  ): Promise<any> {
    const job = await this.jobRepository.findOne({ where: { id: jobId } });
    if (!job) {
      this.logger.error(`executeGenerationJob: Job ${jobId} not found`);
      return;
    }

    try {
      job.progress_stage = 'GENERATING';
      await this.jobRepository.save(job);

      const imageBytes = fs.readFileSync(originalLocalPath);
      const blob = new Blob([imageBytes], { type: 'image/jpeg' });
      const formData = new globalThis.FormData();
      formData.append('image', blob, 'photo.jpg');

      if (dto.sideImageBase64) {
        const sBuf = Buffer.from(dto.sideImageBase64.replace(/^data:image\/\w+;base64,/, ''), 'base64');
        formData.append('side_image', new Blob([sBuf], { type: 'image/jpeg' }), 'side.jpg');
      }
      if (dto.backImageBase64) {
        const bBuf = Buffer.from(dto.backImageBase64.replace(/^data:image\/\w+;base64,/, ''), 'base64');
        formData.append('back_image', new Blob([bBuf], { type: 'image/jpeg' }), 'back.jpg');
      }

      if (dto.hairStyle) formData.append('hair_style', dto.hairStyle);
      if (dto.beardStyle) formData.append('beard_style', dto.beardStyle);
      if (dto.hairColor) formData.append('hair_color', dto.hairColor);
      if (dto.beardColor) formData.append('beard_color', dto.beardColor);
      formData.append('maintenance_level', preferences.maintenance_level);
      formData.append('style_vibe', preferences.style_vibe);
      formData.append('hair_length_pref', preferences.hair_length_pref);
      formData.append('beard_pref', preferences.beard_pref);
      formData.append('mode', dto.mode || 'storyboard');
      formData.append('variations_count', targetCount.toString());

      const aiResponse = await fetch(`${this.aiServiceUrl}/api/v1/generate`, {
        method: 'POST',
        body: formData,
        signal: AbortSignal.timeout(300000), // 5 min timeout on localhost loopback
      });

      if (!aiResponse.ok) {
        const errText = await aiResponse.text();
        let errorDetail = errText;
        try {
          const parsed = JSON.parse(errText);
          if (parsed.detail) errorDetail = parsed.detail;
        } catch (_) {}
        throw new Error(errorDetail);
      }

      const aiData: any = await aiResponse.json();
      if (!aiData || !aiData.variations || !Array.isArray(aiData.variations)) {
        throw new Error('AI service did not return valid variations.');
      }

      let storyboardImageUrl: string | undefined;
      if (aiData.storyboard_image_base64) {
        const sbFilename = `storyboard_${job.id}.png`;
        const sbLocalPath = path.join(this.baseUploadDir, 'generated', sbFilename);
        fs.writeFileSync(sbLocalPath, Buffer.from(aiData.storyboard_image_base64, 'base64'));
        storyboardImageUrl = `/uploads/ai-styles/generated/${sbFilename}`;
      }

      const storedVariations: AiVariationItem[] = [];
      for (let i = 0; i < aiData.variations.length; i++) {
        const item = aiData.variations[i];
        const optNum = item.option_number || i + 1;
        const varFilename = `gen_${job.id}_var_${optNum}.png`;
        const varLocalPath = path.join(this.baseUploadDir, 'generated', varFilename);

        if (item.image_base64) {
          fs.writeFileSync(varLocalPath, Buffer.from(item.image_base64, 'base64'));
        } else if (item.image_url && fs.existsSync(item.image_url)) {
          fs.copyFileSync(item.image_url, varLocalPath);
        }

        // Only store side/back views if genuinely provided/generated for this customer job (never static shared assets)
        let sideImageUrl: string | undefined;
        if (item.side_image_base64 && item.side_view_available) {
          const sideFilename = `gen_${job.id}_side_${optNum}.png`;
          const sideLocalPath = path.join(this.baseUploadDir, 'generated', sideFilename);
          fs.writeFileSync(sideLocalPath, Buffer.from(item.side_image_base64, 'base64'));
          sideImageUrl = `/uploads/ai-styles/generated/${sideFilename}`;
        }

        let backImageUrl: string | undefined;
        if (item.back_image_base64 && item.back_view_available) {
          const backFilename = `gen_${job.id}_back_${optNum}.png`;
          const backLocalPath = path.join(this.baseUploadDir, 'generated', backFilename);
          fs.writeFileSync(backLocalPath, Buffer.from(item.back_image_base64, 'base64'));
          backImageUrl = `/uploads/ai-styles/generated/${backFilename}`;
        }

        storedVariations.push({
          id: item.id || `var_${optNum}`,
          archetype_id: item.archetype_id,
          option_number: optNum,
          image_url: `/uploads/ai-styles/generated/${varFilename}`,
          side_image_url: sideImageUrl,
          back_image_url: backImageUrl,
          side_view_available: Boolean(sideImageUrl),
          back_view_available: Boolean(backImageUrl),
          style_label: item.style_label || `${dto.hairStyle || ''} ${dto.beardStyle || ''}`.trim(),
          hair_style: item.hair_style || dto.hairStyle,
          beard_style: item.beard_style || dto.beardStyle,
          header_hex: item.header_hex,
          hair_length_cm: item.hair_length_cm,
          beard_length_mm: item.beard_length_mm,
          hair_desc: item.hair_desc,
          beard_desc: item.beard_desc,
          look_desc: item.look_desc,
          why_it_suits: item.why_it_suits,
          suitability_score: item.suitability_score,
          maintenance_level: item.maintenance_level,
          styling_products: item.styling_products,
          barber_instructions: item.barber_instructions,
          is_recommended: Boolean(item.is_recommended),
          storyboard_image_url: i === 0 ? storyboardImageUrl : undefined,
          barber_notes: i === 0 ? aiData.barber_notes : undefined,
          best_option: i === 0 ? aiData.best_option : undefined,
          seed: item.seed,
          elapsed_seconds: item.elapsed_seconds,
        });
      }

      job.status =
        storedVariations.length > 0 && storedVariations.length < targetCount
          ? AiJobStatus.PARTIALLY_COMPLETED
          : AiJobStatus.COMPLETED;
      job.completed_variations = storedVariations.length;
      job.progress_stage = 'COMPLETED';
      job.analysis_result = aiData.analysis || null;
      job.storyboard_image_url = storyboardImageUrl || null;
      job.barber_notes = aiData.barber_notes || [];
      job.best_option = aiData.best_option || null;
      job.variations = storedVariations;

      const finalJob = await this.jobRepository.save(job);

      return {
        ...finalJob,
        storyboard_image_url: storyboardImageUrl,
        barber_notes: aiData.barber_notes,
        best_option: aiData.best_option,
        analysis: aiData.analysis,
      };
    } catch (err: any) {
      this.logger.error(`AI style generation failed for job ${job.id}: ${err.message}`);
      job.status = AiJobStatus.FAILED;
      job.progress_stage = 'FAILED';
      job.error_message = `Local AI inference error: ${err.message || 'Service unavailable'}`;
      return await this.jobRepository.save(job);
    }
  }

  async listGenerations(customerId: string): Promise<AiStyleJob[]> {
    return await this.jobRepository.find({
      where: { customer_id: customerId },
      order: { created_at: 'DESC' },
      take: 25,
    });
  }

  async getJob(customerId: string, jobId: string): Promise<any> {
    const job = await this.jobRepository.findOne({ where: { id: jobId } });
    if (!job) throw new NotFoundException('Generation job not found.');
    if (job.customer_id !== customerId) {
      throw new ForbiddenException('Access denied to this generation job.');
    }
    const first = job.variations?.[0];
    return {
      ...job,
      storyboard_image_url: job.storyboard_image_url || first?.storyboard_image_url,
      barber_notes: job.barber_notes || first?.barber_notes,
      best_option: job.best_option || first?.best_option,
      analysis: job.analysis_result,
    };
  }

  async getGenerationLooks(customerId: string, jobId: string): Promise<AiVariationItem[]> {
    const job = await this.getJob(customerId, jobId);
    return job.variations || [];
  }

  async deleteGeneration(customerId: string, jobId: string): Promise<{ success: boolean }> {
    const job = await this.jobRepository.findOne({ where: { id: jobId } });
    if (!job) throw new NotFoundException('Generation job not found.');
    if (job.customer_id !== customerId) {
      throw new ForbiddenException('Access denied to delete this generation job.');
    }

    this.unlinkSafe(job.original_image_url);
    this.unlinkSafe(job.storyboard_image_url);
    for (const v of job.variations || []) {
      this.unlinkSafe(v.image_url);
      this.unlinkSafe(v.side_image_url);
      this.unlinkSafe(v.back_image_url);
      this.unlinkSafe(v.storyboard_image_url);
    }

    await this.jobRepository.remove(job);
    return { success: true };
  }

  async saveLook(customerId: string, dto: SaveLookDto): Promise<AiSavedLook> {
    const look = this.lookRepository.create({
      customer_id: customerId,
      job_id: dto.jobId,
      archetype_id: dto.archetypeId,
      option_number: dto.optionNumber,
      original_image_url: dto.originalImageUrl,
      styled_image_url: dto.styledImageUrl,
      hair_style: dto.hairStyle,
      beard_style: dto.beardStyle,
      title: dto.title || `${dto.hairStyle || 'Hairstyle'} & ${dto.beardStyle || 'Beard'}`.trim(),
      notes: dto.notes,
      why_it_suits: dto.whyItSuits,
      suitability_score: dto.suitabilityScore,
      maintenance_level: dto.maintenanceLevel,
      hair_length_cm: dto.hairLengthCm,
      beard_length_mm: dto.beardLengthMm,
      styling_products: dto.stylingProducts,
      barber_instructions: dto.barberInstructions,
    });
    return await this.lookRepository.save(look);
  }

  async getSavedLooks(customerId: string): Promise<AiSavedLook[]> {
    return await this.lookRepository.find({
      where: { customer_id: customerId },
      order: { created_at: 'DESC' },
    });
  }

  async deleteSavedLook(customerId: string, lookId: string): Promise<{ success: boolean }> {
    const look = await this.lookRepository.findOne({ where: { id: lookId } });
    if (!look) throw new NotFoundException('Saved look not found.');
    if (look.customer_id !== customerId) {
      throw new ForbiddenException('Access denied to delete this look.');
    }
    await this.lookRepository.remove(look);
    return { success: true };
  }

  async shareLook(customerId: string, lookId: string): Promise<any> {
    const look = await this.lookRepository.findOne({ where: { id: lookId } });
    if (!look) throw new NotFoundException('Saved look not found.');
    if (look.customer_id !== customerId) {
      throw new ForbiddenException('Access denied to share this look.');
    }

    if (!look.share_token) {
      look.share_token = `slot_look_${Date.now().toString(36)}_${Math.random().toString(36).substring(2, 8)}`;
      look.is_shared = true;
      await this.lookRepository.save(look);
    }

    return {
      success: true,
      shareToken: look.share_token,
      shareSummary: {
        title: look.title,
        styledImageUrl: look.styled_image_url,
        hairLengthCm: look.hair_length_cm,
        beardLengthMm: look.beard_length_mm,
        maintenanceLevel: look.maintenance_level,
        stylingProducts: look.styling_products,
        barberInstructions: look.barber_instructions || [],
        notes: look.notes,
      },
    };
  }
}
