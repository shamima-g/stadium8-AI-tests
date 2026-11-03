export const readScalarParam = (url: URL, name: string) =>
  url.searchParams.get(name)?.trim() || undefined;

export const readArrayParam = (url: URL, name: string) =>
  url.searchParams.getAll(name).filter(Boolean);

export const paginate = <Item>(items: Item[], url: URL) => {
  const page = Number(readScalarParam(url, 'page') ?? 1);
  const pageSize = Number(readScalarParam(url, 'pageSize') ?? 20);
  return {
    slice: items.slice((page - 1) * pageSize, page * pageSize),
    total: items.length,
    page,
    pageSize,
  };
};

export const paginateByOffset = <Item>(items: Item[], url: URL) => {
  const limit = Number(readScalarParam(url, 'limit') ?? 20);
  const offset = Number(readScalarParam(url, 'offset') ?? 0);
  return {
    slice: items.slice(offset, offset + limit),
    total: items.length,
    limit,
    offset,
  };
};
