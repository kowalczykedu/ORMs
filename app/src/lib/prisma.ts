import "dotenv/config";
import { PrismaClient } from "@prisma/client";

export const prisma = new PrismaClient();

export async function desconectarPrisma(): Promise<void> {
  await prisma.$disconnect();
}
