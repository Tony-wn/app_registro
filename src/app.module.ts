import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { APP_GUARD } from '@nestjs/core';
import { EventEmitterModule } from "@nestjs/event-emitter";

import { DatabaseModule } from "./database/database.module";
import { AuthModule } from "./modules/auth/auth.module";
import { UsuariosModule } from './modules/usuarios/usuarios.module';
import { RolesModule } from './modules/roles/roles.module';
import { QrModule } from './modules/qr/qr.module';
import { MetricsModule } from './modules/metrics/metrics.module';
import { HealthModule } from './modules/health/health.module';

import { JwtAuthGuard } from "./modules/auth/guards/jwt-auth.guard";
import { RolesGuard } from "./modules/auth/guards/roles.guard";
import { PermissionsGuard } from "./modules/auth/guards/permissions.guard";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),  // 1. Config siempre primero
    EventEmitterModule.forRoot(),               // 2. Infraestructura sin deps
    DatabaseModule,                             // 3. Conexiones DB — antes que CUALQUIER módulo que use TypeORM
    AuthModule,                                 // 4. Módulos de negocio
    UsuariosModule,
    RolesModule,
    QrModule,                                   // 5. QrModule después de DatabaseModule
    MetricsModule,
    HealthModule,                                 // 6. HealthModule 
  ],
  providers: [
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    { provide: APP_GUARD, useClass: PermissionsGuard },
  ],
})
export class AppModule {}