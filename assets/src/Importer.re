let component = ReasonReact.statelessComponent("Importer");

let make = (_children) => {
  ...component,
  render: _self => {
    <Main title="Importer">
      <form>
        <fieldset className="bn">
          <legend>{ReasonReact.string("Data Source")}</legend>

        </fieldset>
      </form>
    </Main>
  },
};
