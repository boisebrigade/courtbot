type state = {username: string};
type action =
  | UpdateAccount(string);

let component = ReasonReact.reducerComponent(__MODULE__);

let make = _children => {
  ...component,
  initialState: () => {username: "Admin"},
  reducer: (action, state) =>
    switch (action) {
    | UpdateAccount(name) => ReasonReact.Update({...state, username: name})
    },
  render: self =>
    <Main title="Account">
      <form>
        <fieldset className="bn">
          <legend className="f3"> {ReasonReact.string("Account Settings")} <Help href="/" /> </legend>
          <div className="mt3 ml2">
            <label htmlFor="username"> {ReasonReact.string("Username: ")} </label>
            <input className="db mb2 mt1" type_="text" id="username" name="username" value={self.state.username} />
          </div>
          <div className="mt3 ml2">
            <label htmlFor="password"> {ReasonReact.string("Current Password: ")} </label>
            <input className="db mb2 mt1" type_="password" id="current_password" name="current_password" />
          </div>
          <div className="mt3 ml2">
            <label htmlFor="password"> {ReasonReact.string("New Password: ")} </label>
            <input className="db mb2 mt1" type_="password" id="password" name="new_password" />
          </div>
          <div className="mt3 ml2">
            <label htmlFor="password"> {ReasonReact.string("Confirm Password: ")} </label>
            <input className="db mb2 mt1" type_="password" id="password" name="confirm_password" />
          </div>
        </fieldset>
        <input type_="submit" className="db mt3 ml3" name="submit" value="Save" id="submit" />
      </form>
    </Main>,
};
