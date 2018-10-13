type state = {
  username: string,
  password: string,
  hasValidationError: bool,
  errorList: list(string),
};

type action =
  | ChangeUsername(string)
  | ChangePassword(string)
  | SubmitLogin;

module UserLogin = [%graphql
  {|
  mutation UserLogin($username: String!, $password: String!) {
    userLogin(input: {userName: $username, password: $password}) {
      jwt
    }
  }
|}
];

module UserLoginMutation = ReasonApollo.CreateMutation(UserLogin);

let getValue = event => ReactEvent.Form.target(event)##value;

let reducer = (action, state) =>
  switch (action) {
  | ChangeUsername(username) => ReasonReact.Update({...state, username})
  | ChangePassword(password) => ReasonReact.Update({...state, password})
  | SubmitLogin =>
    let query = UserLogin.make(~username=state.username, ~password=state.password, ()) |> ignore;

    ReasonReact.NoUpdate;
  };

let errorDisplayList = errorList =>
  List.filter(errorMessage => String.length(errorMessage) > 0, errorList)
  |> List.mapi((acc, errorMessage) =>
       <ul className="error-messages" key={string_of_int(acc)}> <li> {ReasonReact.string(errorMessage)} </li> </ul>
     );

let component = ReasonReact.reducerComponent(__MODULE__);

let make = (~successfulLogin, _children) => {
  ...component,
  initialState: () => {username: "", password: "", hasValidationError: false, errorList: []},
  reducer,
  render: self =>
    <UserLoginMutation>
      ...{
           (mutation, {result}) =>
             <div className="flex flex-column justify-center items-center w-100 h-100">
               <div className="bg-near-white pa3">
                 <h3> {ReasonReact.string("Login")} </h3>
                 {
                   switch (result) {
                   | NotCalled => <div />
                   | Data(data) =>
                     switch (data##userLogin) {
                     | Some(login) =>
                       Effects.saveTokenToStorage(login##jwt);
                       successfulLogin();
                       <div />;
                     | None => <div />
                     }
                   | Error(_) => <div> {ReasonReact.string("Invalid Login")} </div>
                   | Loading => <div />
                   }
                 }
                 <form
                   onSubmit={
                     e => {
                       ReactEvent.Form.preventDefault(e);
                       let userLogin =
                         UserLogin.make(~username=self.state.username, ~password=self.state.password, ());

                       userLogin |> Js.log;

                       mutation(~variables=userLogin##variables, ()) |> ignore;
                     }
                   }>
                   <input
                     type_="text"
                     className="db"
                     placeholder="Username"
                     name="username"
                     id="username"
                     onChange={e => self.send(ChangeUsername(getValue(e)))}
                   />
                   <input
                     type_="password"
                     className="db mv3"
                     placeholder="Password"
                     name="password"
                     id="password"
                     onChange={e => self.send(ChangePassword(getValue(e)))}
                   />
                   <input type_="submit" className="db ml-auto" name="submit" id="submit" />
                 </form>
               </div>
             </div>
         }
    </UserLoginMutation>,
};
