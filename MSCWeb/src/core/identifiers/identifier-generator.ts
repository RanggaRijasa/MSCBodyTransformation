export interface IdentifierGenerator {
  makeIdentifier(): string;
}

export class CryptoIdentifierGenerator implements IdentifierGenerator {
  makeIdentifier(): string {
    return crypto.randomUUID();
  }
}

export class FixedIdentifierGenerator implements IdentifierGenerator {
  constructor(private readonly identifier: string) {}

  makeIdentifier(): string {
    return this.identifier;
  }
}
