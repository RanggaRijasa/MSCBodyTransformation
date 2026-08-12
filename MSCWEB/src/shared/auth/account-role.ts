export type AccountRole = 'participant' | 'coach' | 'admin';

export class AccountRoleError extends Error {
  constructor() {
    super('Peran akun tidak dapat diverifikasi. Keluar lalu masuk kembali.');
    this.name = 'AccountRoleError';
  }
}

export function parseAccountRole(value: unknown): AccountRole {
  if (value === 'participant' || value === 'coach' || value === 'admin') return value;
  throw new AccountRoleError();
}

export function destinationForRole(role: AccountRole, intendedRoute: string): string {
  if (role === 'admin') return '/admin';
  if (role === 'coach') return '/coach';
  return intendedRoute;
}
