import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, click } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Component from '@glimmer/component';
import {
  rowPaginationFeature,
  rowSelectionFeature,
  columnVisibilityFeature,
  tableFeatures,
  createPaginatedRowModel,
} from '@tanstack/table-core';
import { useTable } from '../../src/index.js';
import type { ColumnDef } from '@tanstack/table-core';

type Data = { id: string; title: string };

module('Integration | useTable reactivity', function (hooks) {
  setupRenderingTest(hooks);

  test('row model is reactive to pagination changes', async function (assert) {
    const _features = tableFeatures({ rowPaginationFeature });
    const columns: Array<ColumnDef<typeof _features, Data>> = [
      { id: 'id', header: 'Id', accessorKey: 'id' },
      { id: 'title', header: 'Title', accessorKey: 'title' },
    ];

    class TestState {
      @tracked pageSize = 5;
    }
    const testState = new TestState();

    const data = Array.from({ length: 10 }, (_, i) => ({
      id: String(i),
      title: `Title ${i}`,
    }));

    class TestComponent extends Component {
      table = useTable(this, {
        data: () => data,
        columns: () => columns,
        _features: () => _features,
        _rowModels: () => ({
          paginatedRowModel: createPaginatedRowModel(),
        }),
        state: () => ({
          pagination: { pageIndex: 0, pageSize: testState.pageSize },
        }),
      });

      get rowCount() {
        return this.table.getRowModel().rows.length;
      }

      <template>
        <div data-test-row-count>{{this.rowCount}}</div>
      </template>
    }

    await render(<template><TestComponent /></template>);
    assert.dom('[data-test-row-count]').hasText('5', 'initially shows 5 rows');

    testState.pageSize = 3;
    await settled();
    assert.dom('[data-test-row-count]').hasText('3', 'shows 3 rows after page size change');
  });

  test('row selection is reactive', async function (assert) {
    const _features = tableFeatures({ rowSelectionFeature });
    const columns: Array<ColumnDef<typeof _features, Data>> = [
      { id: 'id', header: 'Id', accessorKey: 'id' },
      { id: 'title', header: 'Title', accessorKey: 'title' },
    ];

    class SelectionState {
      @tracked rowSelection: Record<string, boolean> = {};
    }
    const selState = new SelectionState();

    class TestComponent extends Component {
      table = useTable(this, {
        data: () => [
          { id: '0', title: 'A' },
          { id: '1', title: 'B' },
          { id: '2', title: 'C' },
        ],
        columns: () => columns,
        _features: () => _features,
        getRowId: () => ((row: Data) => row.id),
        enableRowSelection: () => true,
        state: () => ({
          rowSelection: selState.rowSelection,
        }),
        onRowSelectionChange: () => ((updater: any) => {
          const newSelection =
            typeof updater === 'function'
              ? updater(selState.rowSelection)
              : updater;
          selState.rowSelection = newSelection;
        }),
      });

      get selectedCount() {
        return Object.keys(selState.rowSelection).length;
      }

      selectFirstRow = () => {
        this.table.getRow('0').toggleSelected(true);
      };

      <template>
        <div data-test-selected-count>{{this.selectedCount}}</div>
        <button type="button" data-test-select-row {{on "click" this.selectFirstRow}}>
          Select
        </button>
      </template>
    }

    await render(<template><TestComponent /></template>);
    assert.dom('[data-test-selected-count]').hasText('0', 'no rows selected initially');

    await click('[data-test-select-row]');
    await settled();
    assert.dom('[data-test-selected-count]').hasText('1', 'one row selected');
  });

  test('data changes are reactive', async function (assert) {
    const _features = tableFeatures({});
    const columns: Array<ColumnDef<typeof _features, Data>> = [
      { id: 'id', header: 'Id', accessorKey: 'id' },
      { id: 'title', header: 'Title', accessorKey: 'title' },
    ];

    class DataState {
      @tracked data: Array<Data> = Array.from({ length: 5 }, (_, i) => ({
        id: String(i),
        title: `Title ${i}`,
      }));
    }
    const dataState = new DataState();

    class TestComponent extends Component {
      table = useTable(this, {
        data: () => dataState.data,
        columns: () => columns,
        _features: () => _features,
      });

      get rowCount() {
        return this.table.getCoreRowModel().rows.length;
      }

      <template>
        <div data-test-row-count>{{this.rowCount}}</div>
      </template>
    }

    await render(<template><TestComponent /></template>);
    assert.dom('[data-test-row-count]').hasText('5', 'initially 5 rows');

    dataState.data = Array.from({ length: 8 }, (_, i) => ({
      id: String(i),
      title: `Title ${i}`,
    }));
    await settled();
    assert.dom('[data-test-row-count]').hasText('8', '8 rows after data update');
  });

  test('column visibility is reactive', async function (assert) {
    const _features = tableFeatures({ columnVisibilityFeature });
    const columns: Array<ColumnDef<typeof _features, Data>> = [
      { id: 'id', header: 'Id', accessorKey: 'id' },
      { id: 'title', header: 'Title', accessorKey: 'title' },
    ];

    class VisState {
      @tracked columnVisibility: Record<string, boolean> = {};
    }
    const visState = new VisState();

    class TestComponent extends Component {
      table = useTable(this, {
        data: () => [{ id: '1', title: 'A' }, { id: '2', title: 'B' }],
        columns: () => columns,
        _features: () => _features,
        state: () => ({
          columnVisibility: visState.columnVisibility,
        }),
        onColumnVisibilityChange: () => ((updater: any) => {
          const newVis =
            typeof updater === 'function'
              ? updater(visState.columnVisibility)
              : updater;
          visState.columnVisibility = newVis;
        }),
      });

      get visibleColumnCount() {
        return this.table.getVisibleLeafColumns().length;
      }

      hideTitle = () => {
        this.table.getColumn('title')!.toggleVisibility(false);
      };

      <template>
        <div data-test-visible-columns>{{this.visibleColumnCount}}</div>
        <button type="button" data-test-hide-column {{on "click" this.hideTitle}}>
          Hide Title
        </button>
      </template>
    }

    await render(<template><TestComponent /></template>);
    assert.dom('[data-test-visible-columns]').hasText('2', 'both columns visible');

    await click('[data-test-hide-column]');
    await settled();
    assert.dom('[data-test-visible-columns]').hasText('1', 'one column visible after hiding title');
  });
});
