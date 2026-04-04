import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';
import { setOwner } from '@ember/owner';
import {
  stockFeatures,
} from '@tanstack/table-core';
import { useTable } from '../../src/index.js';
import type { ColumnDef } from '@tanstack/table-core';

type Data = { id: string; title: string };

const columns: Array<ColumnDef<typeof stockFeatures, Data>> = [
  { id: 'id', header: 'Id', accessorKey: 'id' },
  { id: 'title', header: 'Title', accessorKey: 'title' },
];

const data: Array<Data> = [{ id: '1', title: 'Title' }];

module('Unit | useTable', function (hooks) {
  setupTest(hooks);

  function createContext(owner: object): object {
    const ctx = {};
    setOwner(ctx, owner as any);
    return ctx;
  }

  test('returns a table with expected methods', function (assert) {
    const ctx = createContext(this.owner);
    const table = useTable(ctx, {
      data: () => data,
      _features: () => stockFeatures,
      columns: () => columns,
    });

    assert.ok(table, 'table is defined');
    assert.ok(typeof table.getRowModel === 'function', 'has getRowModel');
    assert.ok(typeof table.getCoreRowModel === 'function', 'has getCoreRowModel');
    assert.ok(typeof table.getHeaderGroups === 'function', 'has getHeaderGroups');
    assert.ok(typeof table.getAllColumns === 'function', 'has getAllColumns');
  });

  test('table properties are accessible', function (assert) {
    const ctx = createContext(this.owner);
    const table = useTable(ctx, {
      data: () => data,
      _features: () => stockFeatures,
      columns: () => columns,
    });

    assert.ok(table._features, '_features is accessible');
    assert.ok(table.options, 'options is accessible');
    assert.strictEqual(table.options.data, data, 'options.data matches input');
  });

  test('supports Object.keys', function (assert) {
    const ctx = createContext(this.owner);
    const table = useTable(ctx, {
      data: () => data,
      _features: () => stockFeatures,
      columns: () => columns,
    });

    const keys = Object.keys(table);
    assert.true(keys.includes('getRowModel'), 'keys include getRowModel');
    assert.true(keys.includes('_features'), 'keys include _features');
  });

  test('returns correct row model', function (assert) {
    const ctx = createContext(this.owner);
    const table = useTable(ctx, {
      data: () => data,
      _features: () => stockFeatures,
      columns: () => columns,
      getRowId: () => ((row: Data) => row.id),
    });

    const rowModel = table.getCoreRowModel();
    assert.strictEqual(rowModel.rows.length, 1, 'has one row');
    assert.strictEqual(
      rowModel.rows[0]?.original.title,
      'Title',
      'row has correct data',
    );
  });
});
