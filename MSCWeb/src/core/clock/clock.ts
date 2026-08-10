export interface Clock {
  now(): Date;
}

export class SystemClock implements Clock {
  now(): Date {
    return new Date();
  }
}

export class FixedClock implements Clock {
  readonly #date: Date;

  constructor(date: Date) {
    this.#date = new Date(date);
  }

  now(): Date {
    return new Date(this.#date);
  }
}
