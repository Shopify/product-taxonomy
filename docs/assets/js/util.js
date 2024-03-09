export const getQueryParam = (param) => {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get(param);
};

export const qq = (selector, context = document) =>
  Array.from(context.querySelectorAll(selector));

export const q = (selector, context = document) =>
  context.querySelector(selector);
