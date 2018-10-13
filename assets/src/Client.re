let inMemoryCache = ApolloInMemoryCache.createInMemoryCache();

let contextHandler = () => {
  let token = Effects.getTokenFromStorge();

  let headers = {
    "headers": {
      "authorization": {j|Bearer $token|j},
    },
  };

  headers;
};

let httpLink = ApolloLinks.createHttpLink(~uri="http://localhost:4000/graphql", ());

let authLink = ApolloLinks.createContextLink(contextHandler);

let instance =
  ReasonApollo.createApolloClient(~link=ApolloLinks.from([|authLink, httpLink|]), ~cache=inMemoryCache, ());
