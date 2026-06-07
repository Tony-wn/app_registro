import { Test, TestingModule } from '@nestjs/testing';
import { ServiceUnavailableException } from '@nestjs/common';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';

const mockHealthyResponse = {
  status: 'ok',
  timestamp: '2025-01-01T00:00:00.000Z',
  uptime: 120,
  version: '1.0.0',
  environment: 'test',
  checks: {
    database: { ok: true, latencyMs: 5 },
    memory: { ok: true, usedMb: 80, heapMb: 45 },
  },
};

describe('HealthController', () => {
  let controller: HealthController;
  let service: HealthService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        {
          provide: HealthService,
          useValue: { check: jest.fn() },
        },
      ],
    }).compile();

    controller = module.get<HealthController>(HealthController);
    service = module.get<HealthService>(HealthService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should return 200 with ok status when DB is up', async () => {
    jest.spyOn(service, 'check').mockResolvedValue(mockHealthyResponse);
    const result = await controller.check();
    expect(result.status).toBe('ok');
    expect(result.checks.database.ok).toBe(true);
  });

  it('should throw ServiceUnavailableException when DB is down', async () => {
    jest.spyOn(service, 'check').mockRejectedValue(
      new ServiceUnavailableException({ status: 'degraded' }),
    );
    await expect(controller.check()).rejects.toThrow(ServiceUnavailableException);
  });
});
