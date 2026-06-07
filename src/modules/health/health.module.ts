import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';

@Module({
  // Necesitamos acceder al DataSource 'SEGURIDAD_DB' que registra DatabaseModule.
  // Al importar TypeOrmModule.forFeature con el nombre de la conexión,
  // NestJS hace disponible el DataSource para inyección.
  imports: [TypeOrmModule.forFeature([], 'SEGURIDAD_DB')],
  controllers: [HealthController],
  providers: [HealthService],
})
export class HealthModule {}
