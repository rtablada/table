import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  useTable,
  flexRenderCell,
  flexRenderHeader,
  tableFeatures,
  rowSortingFeature,
  rowPaginationFeature,
  createSortedRowModel,
  createPaginatedRowModel,
  sortFns,
  createColumnHelper,
  type Column,
  type Row,
  type Cell,
  type SortingState,
  type PaginationState,
} from '@tanstack/ember-table';
import { createAtom } from '@tanstack/store';
import { makeData, type Person } from '../utils/make-data';

// This example demonstrates managing individual slices of table state via
// external TanStack Store atoms. Each atom is a stand-alone, subscribable
// reactive cell — you can read, write, or subscribe to it from anywhere,
// which makes it convenient for sharing state across components or modules.

const features = tableFeatures({
  rowPaginationFeature,
  rowSortingFeature,
  sortedRowModel: createSortedRowModel(),
  paginatedRowModel: createPaginatedRowModel(),
  sortFns,
});

const columnHelper = createColumnHelper<typeof features, Person>();

const columns = columnHelper.columns([
  columnHelper.accessor('firstName', {
    header: 'First Name',
    cell: (info) => info.getValue(),
  }),
  columnHelper.accessor('lastName', {
    header: 'Last Name',
    cell: (info) => info.getValue(),
  }),
  columnHelper.accessor('age', {
    header: 'Age',
  }),
  columnHelper.accessor('visits', {
    header: 'Visits',
  }),
  columnHelper.accessor('status', {
    header: 'Status',
  }),
  columnHelper.accessor('progress', {
    header: 'Profile Progress',
  }),
]);

const PAGE_SIZES = [10, 20, 30, 40, 50];

const getCanSort = (column: Column<typeof features, Person>): boolean =>
  column.getCanSort();
const getAllCells = (
  row: Row<typeof features, Person>,
): Array<Cell<typeof features, Person>> => row.getAllCells();
const lookup = (obj: Record<string, unknown>, key: string): unknown =>
  obj[key];
const not = (value: unknown): boolean => !value;
const eq = (a: unknown, b: unknown): boolean => String(a) === String(b);

const toggleSort = (column: Column<typeof features, Person>) => {
  return (event: Event) => {
    column.getToggleSortingHandler()?.(event);
  };
};

export default class BasicTable extends Component {
  @tracked data: Array<Person> = makeData(1_000);

  // Create stable external atoms for the individual state slices you want to
// own. These live at module scope here, but could just as easily be created
// in a shared store module and imported by multiple components.
 sortingAtom = createAtom<SortingState>([]);
 paginationAtom = createAtom<PaginationState>({
  pageIndex: 0,
  pageSize: 10,
});



  tableManager = useTable(this, () => ({
    features,
    columns,
    data: this.data,
    atoms: {
      sorting: this.sortingAtom,
      pagination: this.paginationAtom,
    },
  }));

  get table() {
    return this.tableManager.table;
  }

  get headerGroups() {
    return this.table.getHeaderGroups();
  }

  get rows() {
    return this.table.getRowModel().rows;
  }

  get tableState() {
    return JSON.stringify(this.table.store.state, null, 2);
  }

  get sortIndicators(): Record<string, string> {
    const indicators: Record<string, string> = {};
    for (const hg of this.table.getHeaderGroups()) {
      for (const h of hg.headers) {
        const sorted = h.column.getIsSorted();
        indicators[h.column.id] =
          sorted === 'asc' ? ' 🔼' : sorted === 'desc' ? ' 🔽' : '';
      }
    }
    return indicators;
  }

  get pagination() {
    return this.paginationAtom.get();
  }

  get canPreviousPage() {
    return this.table.getCanPreviousPage();
  }

  get canNextPage() {
    return this.table.getCanNextPage();
  }

  get pageCount() {
    return this.table.getPageCount();
  }

  get currentPage() {
    return (this.pagination.pageIndex + 1).toLocaleString();
  }

  get pageCountDisplay() {
    return this.table.getPageCount().toLocaleString();
  }

  get currentPageInputValue() {
    return String(this.pagination.pageIndex + 1);
  }

  get pageSizes() {
    return PAGE_SIZES;
  }

  regenerateData = () => {
    this.data = makeData(1_000);
  };

  stressTest = () => {
    this.data = makeData(1_000_000);
  };

  goToFirstPage = () => {
    this.table.setPageIndex(0);
  };

  goToPreviousPage = () => {
    this.table.previousPage();
  };

  goToNextPage = () => {
    this.table.nextPage();
  };

  goToLastPage = () => {
    this.table.setPageIndex(this.table.getPageCount() - 1);
  };

  handleGoToPage = (event: Event) => {
    const target = event.currentTarget as HTMLInputElement;
    const page = target.value ? Number(target.value) - 1 : 0;
    this.table.setPageIndex(page);
  };

  handlePageSizeChange = (event: Event) => {
    const target = event.currentTarget as HTMLSelectElement;
    this.table.setPageSize(Number(target.value));
  };

  <template>
    <div class="demo-root">
      <div>
        <button type="button" {{on "click" this.regenerateData}}>
          Regenerate Data
        </button>
        <button type="button" {{on "click" this.stressTest}}>
          Stress Test (1M rows)
        </button>
      </div>
      <table>
        <thead>
          {{#each this.headerGroups as |headerGroup|}}
            <tr>
              {{#each headerGroup.headers as |header|}}
                <th colspan={{header.colSpan}}>
                  {{#unless header.isPlaceholder}}
                    <div
                      class="{{if (getCanSort header.column) 'sortable-header'}}"
                      {{on "click" (toggleSort header.column)}}
                    >
                      {{flexRenderHeader header}}{{lookup this.sortIndicators header.column.id}}
                    </div>
                  {{/unless}}
                </th>
              {{/each}}
            </tr>
          {{/each}}
        </thead>
        <tbody>
          {{#each this.rows as |row|}}
            <tr>
              {{#each (getAllCells row) as |cell|}}
                <td>{{flexRenderCell cell}}</td>
              {{/each}}
            </tr>
          {{/each}}
        </tbody>
      </table>
      <div class="spacer-sm"></div>
      <div class="controls">
        <button
          class="demo-button demo-button-sm"
          disabled={{not this.canPreviousPage}} type="button" {{on "click" this.goToFirstPage}}
        >
          &lt;&lt;
        </button>
        <button
          class="demo-button demo-button-sm"
          disabled={{not this.canPreviousPage}} type="button" {{on "click" this.goToPreviousPage}}
        >
          &lt;
        </button>
        <button
          class="demo-button demo-button-sm"
          disabled={{not this.canNextPage}} type="button" {{on "click" this.goToNextPage}}
        >
          &gt;
        </button>
        <button
          class="demo-button demo-button-sm"
          disabled={{not this.canNextPage}} type="button" {{on "click" this.goToLastPage}}
        >
          &gt;&gt;
        </button>
        <span class="inline-controls">
          <div>Page</div>
          <strong>
            {{this.currentPage}} of {{this.pageCountDisplay}}
          </strong>
        </span>
        <span class="inline-controls">
          | Go to page:
          <input
            type="number"
            min="1"
            max={{this.pageCount}}
            value={{this.currentPageInputValue}}
            class="page-size-input"
            {{on "input" this.handleGoToPage}}
          />
        </span>
        <select
          {{on "change" this.handlePageSizeChange}}
        >
          {{#each this.pageSizes as |pageSize|}}
            <option value={{pageSize}} selected={{eq pageSize this.pagination.pageSize}}>
              Show {{pageSize}}
            </option>
          {{/each}}
        </select>
      </div>
      <div class="spacer-md"></div>
      <pre>{{this.tableState}}</pre>
    </div>
  </template>
}
