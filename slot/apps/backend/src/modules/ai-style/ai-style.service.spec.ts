import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { AiStyleService } from './ai-style.service';
import { AiStyleJob } from '../../entities/ai-style-job.entity';
import { AiSavedLook } from '../../entities/ai-saved-look.entity';
import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';

describe('AiStyleService', () => {
  let service: AiStyleService;
  let jobRepoMock: any;
  let lookRepoMock: any;

  beforeEach(async () => {
    jobRepoMock = {
      create: jest.fn((dto) => ({ id: 'mock-job-id', ...dto })),
      save: jest.fn((entity) => Promise.resolve(entity)),
      find: jest.fn().mockResolvedValue([]),
      findOne: jest.fn(),
      remove: jest.fn().mockResolvedValue(true),
    };

    lookRepoMock = {
      create: jest.fn((dto) => ({ id: 'mock-look-id', ...dto })),
      save: jest.fn((entity) => Promise.resolve(entity)),
      find: jest.fn().mockResolvedValue([]),
      findOne: jest.fn(),
      remove: jest.fn().mockResolvedValue(true),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiStyleService,
        {
          provide: getRepositoryToken(AiStyleJob),
          useValue: jobRepoMock,
        },
        {
          provide: getRepositoryToken(AiSavedLook),
          useValue: lookRepoMock,
        },
      ],
    }).compile();

    service = module.get<AiStyleService>(AiStyleService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should return configured style options and dynamic preference filters', () => {
    const options = service.getStyleOptions();
    expect(options.hairStyles.length).toBeGreaterThanOrEqual(10);
    expect(options.beardStyles.length).toBeGreaterThan(0);
    expect(options.preferenceOptions.maintenanceLevels.length).toBeGreaterThan(0);
    expect(options.preferenceOptions.styleVibes.length).toBeGreaterThan(0);
    expect(options.hairStyles.find((h) => h.id === 'textured_crop')).toBeDefined();
    expect(options.beardStyles.find((b) => b.id === 'clean_shaven')).toBeDefined();
  });

  it('should reject generation when consent is false', async () => {
    await expect(
      service.generateStyle('cust-1', {
        consentGiven: false,
        hairStyle: 'textured_crop',
      } as any),
    ).rejects.toThrow(BadRequestException);
  });

  it('should reject generation when no photo is provided', async () => {
    await expect(
      service.generateStyle('cust-1', {
        consentGiven: true,
      } as any),
    ).rejects.toThrow(BadRequestException);
  });

  it('should prevent cross-user access to generation jobs', async () => {
    jobRepoMock.findOne.mockResolvedValue({
      id: 'job-1',
      customer_id: 'cust-owner',
    });

    await expect(service.getJob('cust-attacker', 'job-1')).rejects.toThrow(ForbiddenException);
  });

  it('should prevent cross-user deletion of generation jobs', async () => {
    jobRepoMock.findOne.mockResolvedValue({
      id: 'job-1',
      customer_id: 'cust-owner',
      variations: [],
    });

    await expect(service.deleteGeneration('cust-attacker', 'job-1')).rejects.toThrow(ForbiddenException);
  });

  it('should allow owner to delete generation job', async () => {
    jobRepoMock.findOne.mockResolvedValue({
      id: 'job-1',
      customer_id: 'cust-owner',
      original_image_url: '/uploads/ai-styles/originals/nonexistent.jpg',
      variations: [],
    });

    const res = await service.deleteGeneration('cust-owner', 'job-1');
    expect(res.success).toBe(true);
    expect(jobRepoMock.remove).toHaveBeenCalled();
  });

  it('should prevent cross-user deletion of saved looks', async () => {
    lookRepoMock.findOne.mockResolvedValue({
      id: 'look-1',
      customer_id: 'cust-owner',
    });

    await expect(service.deleteSavedLook('cust-attacker', 'look-1')).rejects.toThrow(ForbiddenException);
  });

  it('should generate a share token and barber summary for owner look', async () => {
    lookRepoMock.findOne.mockResolvedValue({
      id: 'look-1',
      customer_id: 'cust-owner',
      title: 'Classic Taper + Short Boxed Beard',
      styled_image_url: '/uploads/ai-styles/generated/gen_1.png',
      hair_length_cm: '5–7 cm top',
      beard_length_mm: '4–6 mm boxed beard',
      maintenance_level: 'low',
      barber_instructions: ['Low taper on sides'],
    });

    const shareRes = await service.shareLook('cust-owner', 'look-1');
    expect(shareRes.success).toBe(true);
    expect(shareRes.shareToken).toContain('slot_look_');
    expect(shareRes.shareSummary.title).toBe('Classic Taper + Short Boxed Beard');
  });

  it('should throw NotFoundException when sharing unknown look', async () => {
    lookRepoMock.findOne.mockResolvedValue(null);
    await expect(service.shareLook('cust-owner', 'missing-id')).rejects.toThrow(NotFoundException);
  });
});
