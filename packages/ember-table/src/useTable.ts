import { constructTable } from '@tanstack/table-core';
import { resource, cell } from 'ember-resources';
import type {
  RowData,
  Table,
  TableFeatures,
  TableOptions,
} from '@tanstack/table-core';

export type EmberTable<
  TFeatures extends TableFeatures,
  TData extends RowData,
> = Table<TFeatures, TData>;

/**
 * Each property is a zero-arg function (thunk) that returns its value.
 * Each thunk is individually tracked by Ember's autotracking system.
 */
export type ReactiveTableOptions<
  TFeatures extends TableFeatures,
  TData extends RowData,
> = {
  [K in keyof TableOptions<TFeatures, TData>]: () => TableOptions<TFeatures, TData>[K];
};

function resolveOptions<
  TFeatures extends TableFeatures,
  TData extends RowData,
>(reactive: ReactiveTableOptions<TFeatures, TData>): TableOptions<TFeatures, TData> {
  const resolved = {} as Record<string, unknown>;
  for (const key of Object.keys(reactive)) {
    resolved[key] = (reactive as Record<string, () => unknown>)[key]!();
  }
  return resolved as TableOptions<TFeatures, TData>;
}

/**
 * Patch store.state getter to read a notifier cell, entangling
 * any Ember autotracking consumer with the notifier.
 *
 * The `guard` flag prevents the notifier read during resource body
 * evaluation (e.g. when setOptions internally reads store.state),
 * so the resource cache is never entangled with the notifier.
 */
function bindStoreToNotifier(
  store: { state: any },
  notifier: { current: number },
  guard: { active: boolean },
) {
  const proto = Object.getPrototypeOf(store);
  const desc = Object.getOwnPropertyDescriptor(proto, 'state');
  if (!desc?.get) return;

  const originalGet = desc.get;
  Object.defineProperty(store, 'state', {
    configurable: true,
    enumerable: true,
    get() {
      if (!guard.active) {
        void notifier.current;
      }
      return originalGet.call(store);
    },
  });
}

export function useTable<
  TFeatures extends TableFeatures,
  TData extends RowData,
>(
  context: object,
  reactiveOptions: ReactiveTableOptions<TFeatures, TData>,
): EmberTable<TFeatures, TData> {
  const notifier = cell(0);
  const guard = { active: false };

  let table: Table<TFeatures, TData> | undefined;
  let stateSub: { unsubscribe: () => void } | undefined;
  let optionsSub: { unsubscribe: () => void } | undefined;
  let pendingNotify = false;

  function scheduleNotify() {
    if (pendingNotify) return;
    pendingNotify = true;
    Promise.resolve().then(() => {
      pendingNotify = false;
      notifier.set(notifier.current + 1);
    });
  }

  return resource(context, ({ on }) => {
    // Guard: prevent notifier reads from entangling the resource cache.
    guard.active = true;

    try {
      const options = resolveOptions(reactiveOptions);

      if (!table) {
        table = constructTable(options);

        bindStoreToNotifier(table.store, notifier, guard);
        bindStoreToNotifier(table.optionsStore, notifier, guard);

        stateSub = table.store.subscribe(scheduleNotify);
        optionsSub = table.optionsStore.subscribe(scheduleNotify);

        on.cleanup(() => {
          stateSub?.unsubscribe();
          optionsSub?.unsubscribe();
          table = undefined;
        });
      } else {
        // Update options directly on the optionsStore to avoid
        // table-core firing onChange callbacks during setOptions,
        // which would reset controlled state.
        table.optionsStore.setState(() => ({
          ...table.options,
          ...options,
        }));
      }

      return table;
    } finally {
      guard.active = false;
    }
  }) as unknown as EmberTable<TFeatures, TData>;
}
