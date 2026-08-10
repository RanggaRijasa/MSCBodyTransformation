export type Result<Value, Failure> =
  Readonly<{ isSuccess: true; value: Value }> | Readonly<{ isSuccess: false; error: Failure }>;

export function success<Value>(value: Value): Result<Value, never> {
  return { isSuccess: true, value };
}

export function failure<Failure>(error: Failure): Result<never, Failure> {
  return { isSuccess: false, error };
}
