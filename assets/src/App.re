type route =
  | Dashboard
  | Configuration
  | Importer
  | Stats
  | Account
  | NotFound;

type state = {
  route,
  needsLogin: bool,
};

type action =
  | ChangeRoute(route)
  | Authenticated;

let mapPathToRoute = (url: ReasonReact.Router.url) =>
  switch (url.path) {
  | [] => Dashboard
  | ["configuration"] => Configuration
  | ["importer"] => Importer
  | ["account"] => Account
  | ["stats"] => Stats
  | _ => NotFound
  };

let component = ReasonReact.reducerComponent(__MODULE__);

let make = _children => {
  ...component,
  initialState: () => {route: mapPathToRoute(ReasonReact.Router.dangerouslyGetInitialUrl()), needsLogin: true},
  didMount: self => {
    let watcherId = ReasonReact.Router.watchUrl(url => self.send(ChangeRoute(url |> mapPathToRoute)));

    self.onUnmount(() => ReasonReact.Router.unwatchUrl(watcherId));
  },
  reducer: (action, _state) =>
    switch (action) {
    | ChangeRoute(route) => ReasonReact.Update({route, needsLogin: false})
    | Authenticated => ReasonReact.Update({route: Dashboard, needsLogin: false})
    },
  render: self => {
    let successfulLogin = () => {
      ReasonReact.(self.send(Authenticated));
      ReasonReact.Router.push("/");
    };
    <>
      {
        self.state.needsLogin ?
          <Login successfulLogin /> :
          <>
            <Aside />
            {
              switch (self.state.route) {
              | Dashboard => <Dashboard />
              | Configuration => <ConfigurationInit />
              | Importer => <Importer />
              | Account => <Account />
              | Stats => <Stats />
              | _ => <NotFound />
              }
            }
          </>
      }
    </>;
  },
};
