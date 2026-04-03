import { createSolidPlugin } from '@tanstack/devtools-utils/solid'
import { TableDevtoolsPanel } from './TableDevtools'
import type { TanStackDevtoolsPlugin } from '@tanstack/devtools'

const [tableDevtoolsPluginFn] = createSolidPlugin({
  name: 'TanStack Table',
  Component: TableDevtoolsPanel,
})

export const tableDevtoolsPlugin: () => TanStackDevtoolsPlugin =
  tableDevtoolsPluginFn
