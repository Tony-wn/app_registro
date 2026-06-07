import {
  Injectable,
  ServiceUnavailableException,
  Logger,
} from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

@Injectable()
export class HealthService {
  private readonly logger = new Logger(HealthService.name);

  constructor(
    @InjectDataSource('SEGURIDAD_DB')
    private readonly seguridadDS: DataSource,
  ) {}

  async check() {
    const dbStatus = await this.checkDatabase();

    const payload = {
      status: dbStatus.ok ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: Math.floor(process.uptime()),
      version: process.env.npm_package_version ?? '1.0.0',
      environment: process.env.NODE_ENV ?? 'development',
      checks: {
        database: dbStatus,
        memory: this.checkMemory(),
      },
    };

    // Si la BD está caída devolvemos 503 (Kubernetes marca el pod como Not Ready)
    if (!dbStatus.ok) {
      this.logger.warn('Health check falló: base de datos no disponible');
      throw new ServiceUnavailableException(payload);
    }

    return payload;
  }

  private async checkDatabase(): Promise<{ ok: boolean; latencyMs?: number; error?: string }> {
    const start = Date.now();
    try {
      await this.seguridadDS.query('SELECT 1');
      return { ok: true, latencyMs: Date.now() - start };
    } catch (err) {
      return { ok: false, error: (err as Error).message };
    }
  }

  private checkMemory(): { ok: boolean; usedMb: number; heapMb: number } {
    const mem = process.memoryUsage();
    return {
      ok: true,
      usedMb: Math.round(mem.rss / 1024 / 1024),
      heapMb: Math.round(mem.heapUsed / 1024 / 1024),
    };
  }
}
