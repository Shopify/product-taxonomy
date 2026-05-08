import {setupValues, setValue} from './values.js';
import {setupSearch} from './search.js';

document.addEventListener('DOMContentLoaded', () => {
  setupValues();
  setupSearch(
    'value-search',
    'value-search-results',
    '../value_search_index.json',
    setValue,
    20,
    [
      {name: 'title', weight: 0.5},
      {name: 'value.name', weight: 1},
      {name: 'value.handle', weight: 0.8},
    ],
  );
});
