import {setupNodes, resetToCategory} from './nodes.js';
import {setupSearch} from './search.js';

document.addEventListener('DOMContentLoaded', () => {
  setupNodes();
  setupSearch('search', 'search-results', './search_index.json', resetToCategory, 20, [
    {name: 'title', weight: 0.5},
    {name: 'category.name', weight: 1},
    {name: 'category.id', weight: 0.8},
  ]);
});
