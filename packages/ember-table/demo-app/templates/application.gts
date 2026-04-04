import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';
import {
  columnFilteringFeature,
  columnVisibilityFeature,
  createFilteredRowModel,
  createPaginatedRowModel,
  createSortedRowModel,
  filterFns,
  rowPaginationFeature,
  rowSelectionFeature,
  rowSortingFeature,
  sortFns,
  tableFeatures,
} from '@tanstack/table-core';
import { useTable } from '../../src/index.js';
import { makeData } from '../lib/make-data.ts';
import type { ColumnDef, SortingState, PaginationState } from '@tanstack/table-core';
import type { Person } from '../lib/make-data.ts';

const _features = tableFeatures({
  rowSortingFeature,
  rowPaginationFeature,
  rowSelectionFeature,
  columnFilteringFeature,
  columnVisibilityFeature,
});

const columns: Array<ColumnDef<typeof _features, Person>> = [
  { id: 'firstName', accessorKey: 'firstName', header: 'First Name' },
  { id: 'lastName', accessorKey: 'lastName', header: 'Last Name' },
  { id: 'age', accessorKey: 'age', header: 'Age' },
  { id: 'email', accessorKey: 'email', header: 'Email' },
  { id: 'status', accessorKey: 'status', header: 'Status' },
  { id: 'department', accessorKey: 'department', header: 'Department' },
  { id: 'joinDate', accessorKey: 'joinDate', header: 'Join Date' },
];

class KitchenSink extends Component {
  @tracked data = makeData(100);
  @tracked sorting: SortingState = [];
  @tracked pagination: PaginationState = { pageIndex: 0, pageSize: 10 };
  @tracked rowSelection: Record<string, boolean> = {};
  @tracked columnVisibility: Record<string, boolean> = {};
  @tracked globalFilter = '';

  table = useTable(this, {
    data: () => this.data,
    columns: () => columns,
    _features: () => _features,
    _rowModels: () => ({
      sortedRowModel: createSortedRowModel(sortFns),
      filteredRowModel: createFilteredRowModel(filterFns),
      paginatedRowModel: createPaginatedRowModel(),
    }),
    state: () => ({
      sorting: this.sorting,
      pagination: this.pagination,
      rowSelection: this.rowSelection,
      columnVisibility: this.columnVisibility,
      globalFilter: this.globalFilter,
    }),
    onSortingChange: () => (updater: any) => {
      this.sorting = typeof updater === 'function' ? updater(this.sorting) : updater;
    },
    onPaginationChange: () => (updater: any) => {
      this.pagination = typeof updater === 'function' ? updater(this.pagination) : updater;
    },
    onRowSelectionChange: () => (updater: any) => {
      this.rowSelection = typeof updater === 'function' ? updater(this.rowSelection) : updater;
    },
    onColumnVisibilityChange: () => (updater: any) => {
      this.columnVisibility = typeof updater === 'function' ? updater(this.columnVisibility) : updater;
    },
    onGlobalFilterChange: () => (updater: any) => {
      this.globalFilter = typeof updater === 'function' ? updater(this.globalFilter) : updater;
    },
    enableRowSelection: () => true,
    getRowId: () => ((row: Person) => row.id),
    globalFilterFn: () => 'includesString' as any,
  });

  get headerGroups() {
    return this.table.getHeaderGroups().map((group: any) => ({
      id: group.id,
      headers: group.headers.map((header: any) => {
        const sorted = header.column.getIsSorted();
        return {
          id: header.id,
          columnId: header.column.id,
          label: header.column.columnDef.header,
          isVisible: header.column.getIsVisible(),
          sortIndicator: sorted === 'asc' ? ' ↑' : sorted === 'desc' ? ' ↓' : '',
        };
      }),
    }));
  }

  get rows() {
    return this.table.getRowModel().rows.map((row: any) => ({
      id: row.id,
      isSelected: row.getIsSelected(),
      cells: row.getVisibleCells().map((cell: any) => ({
        id: cell.id,
        value: cell.getValue(),
      })),
      toggleSelected: () => row.toggleSelected(),
    }));
  }

  get pageCount() {
    return this.table.getPageCount();
  }

  get currentPage() {
    return this.pagination.pageIndex + 1;
  }

  get canPrevPage() {
    return this.table.getCanPreviousPage();
  }

  get canNextPage() {
    return this.table.getCanNextPage();
  }

  get selectedCount() {
    return Object.keys(this.rowSelection).length;
  }

  get allColumns() {
    return this.table.getAllLeafColumns().map((col: any) => ({
      id: col.id,
      isVisible: col.getIsVisible(),
    }));
  }

  get isAllRowsSelected() {
    return this.table.getIsAllRowsSelected();
  }

  refreshData = () => {
    this.data = makeData(100);
  };

  setGlobalFilter = (e: Event) => {
    this.globalFilter = (e.target as HTMLInputElement).value;
  };

  goFirstPage = () => this.table.setPageIndex(0);
  goPrevPage = () => this.table.previousPage();
  goNextPage = () => this.table.nextPage();
  goLastPage = () => this.table.setPageIndex(this.pageCount - 1);

  setPageSize = (e: Event) => {
    this.table.setPageSize(Number((e.target as HTMLSelectElement).value));
  };

  toggleAllRows = () => {
    this.table.toggleAllRowsSelected();
  };

  toggleColumnVisibility = (columnId: string) => {
    const col = this.table.getColumn(columnId);
    if (col) col.toggleVisibility();
  };

  toggleSort = (columnId: string) => {
    const col = this.table.getColumn(columnId);
    if (col) col.toggleSorting();
  };

  toggleRowSelected = (rowId: string) => {
    const row = this.table.getRow(rowId);
    if (row) row.toggleSelected();
  };

  <template>
    {{pageTitle "Kitchen Sink Demo"}}

    <div style="font-family: sans-serif; padding: 1rem; max-width: 1200px; margin: 0 auto;">
      <h1>@tanstack/ember-table Kitchen Sink</h1>

      {{! Toolbar }}
      <div style="display: flex; gap: 0.5rem; margin-bottom: 1rem; flex-wrap: wrap; align-items: center;">
        <input
          type="text"
          placeholder="Global filter..."
          value={{this.globalFilter}}
          {{on "input" this.setGlobalFilter}}
          style="padding: 0.4rem; border: 1px solid #ccc; border-radius: 4px;"
        />
        <button type="button" {{on "click" this.refreshData}}
          style="padding: 0.4rem 0.8rem; border: 1px solid #ccc; border-radius: 4px; cursor: pointer;">
          Refresh Data
        </button>
        <span style="margin-left: auto; font-size: 0.9em; color: #666;">
          {{this.selectedCount}} row(s) selected
        </span>
      </div>

      {{! Column Visibility }}
      <details style="margin-bottom: 1rem;">
        <summary style="cursor: pointer; font-weight: bold;">Column Visibility</summary>
        <div style="display: flex; gap: 1rem; flex-wrap: wrap; padding: 0.5rem 0;">
          {{#each this.allColumns as |column|}}
            <label style="display: flex; align-items: center; gap: 0.25rem; font-size: 0.9em;">
              <input
                type="checkbox"
                checked={{column.isVisible}}
                {{on "change" (fn this.toggleColumnVisibility column.id)}}
              />
              {{column.id}}
            </label>
          {{/each}}
        </div>
      </details>

      {{! Table }}
      <div style="overflow-x: auto; border: 1px solid #ddd; border-radius: 4px;">
        <table style="width: 100%; border-collapse: collapse; font-size: 0.9em;">
          <thead>
            {{#each this.headerGroups as |headerGroup|}}
              <tr style="background: #f5f5f5;">
                <th style="padding: 0.5rem; border-bottom: 2px solid #ddd; text-align: left; width: 40px;">
                  <input
                    type="checkbox"
                    checked={{this.isAllRowsSelected}}
                    {{on "change" this.toggleAllRows}}
                  />
                </th>
                {{#each headerGroup.headers as |header|}}
                  {{#if header.isVisible}}
                    <th
                      style="padding: 0.5rem; border-bottom: 2px solid #ddd; text-align: left; cursor: pointer; user-select: none;"
                      {{on "click" (fn this.toggleSort header.columnId)}}
                    >
                      {{header.label}}{{header.sortIndicator}}
                    </th>
                  {{/if}}
                {{/each}}
              </tr>
            {{/each}}
          </thead>
          <tbody>
            {{#each this.rows as |row|}}
              <tr style="border-bottom: 1px solid #eee; {{if row.isSelected 'background: #e8f4fd;' ''}}">
                <td style="padding: 0.4rem 0.5rem;">
                  <input
                    type="checkbox"
                    checked={{row.isSelected}}
                    {{on "change" row.toggleSelected}}
                  />
                </td>
                {{#each row.cells as |cell|}}
                  <td style="padding: 0.4rem 0.5rem;">
                    {{cell.value}}
                  </td>
                {{/each}}
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>

      {{! Pagination }}
      <div style="display: flex; gap: 0.5rem; align-items: center; margin-top: 1rem; flex-wrap: wrap;">
        <button type="button" {{on "click" this.goFirstPage}}
          style="padding: 0.3rem 0.6rem; border: 1px solid #ccc; border-radius: 4px; cursor: pointer;">
          «
        </button>
        <button type="button" {{on "click" this.goPrevPage}}
          style="padding: 0.3rem 0.6rem; border: 1px solid #ccc; border-radius: 4px; cursor: pointer;">
          ‹
        </button>
        <span style="font-size: 0.9em;">
          Page {{this.currentPage}} of {{this.pageCount}}
        </span>
        <button type="button" {{on "click" this.goNextPage}}
          style="padding: 0.3rem 0.6rem; border: 1px solid #ccc; border-radius: 4px; cursor: pointer;">
          ›
        </button>
        <button type="button" {{on "click" this.goLastPage}}
          style="padding: 0.3rem 0.6rem; border: 1px solid #ccc; border-radius: 4px; cursor: pointer;">
          »
        </button>
        <select {{on "change" this.setPageSize}}
          style="padding: 0.3rem; border: 1px solid #ccc; border-radius: 4px;">
          <option value="10">10</option>
          <option value="20">20</option>
          <option value="50">50</option>
          <option value="100">100</option>
        </select>
        <span style="font-size: 0.9em; color: #666;">
          rows per page
        </span>
      </div>
    </div>
  </template>
}

<template>
  <KitchenSink />
</template>
