type types =
  | CSV
  | JSON;

type origins =
  | FILE
  | URL;

type state = {
  dataType: types,
  dataOrigin: origins,
  dataSource: string,
};

type action =
  | UpdateType(string)
  | UpdateSource(string)
  | UpdateOrigin(string);

type importer = {
  fieldTo: string,
  fieldFrom: string,
  fieldType: string,
  format: string,
  order: int,
};

let component = ReasonReact.reducerComponent(__MODULE__);

let getValue = event => ReactEvent.Form.target(event)##value;

let make = (~kind="CSV", ~origin="URL", ~source, _children) => {
  ...component,
  initialState: () => {dataType: CSV, dataOrigin: FILE, dataSource: ""},
  reducer: (action, state) =>
    switch (action) {
    | UpdateType("csv") => ReasonReact.Update({...state, dataType: CSV})
    | UpdateType("json") => ReasonReact.Update({...state, dataType: JSON})
    | UpdateType(_) => ReasonReact.Update({...state, dataType: CSV})
    | UpdateOrigin("file") => ReasonReact.Update({...state, dataOrigin: FILE})
    | UpdateOrigin("url") => ReasonReact.Update({...state, dataOrigin: URL})
    | UpdateOrigin(_) => ReasonReact.Update({...state, dataOrigin: URL})
    | UpdateSource(source) => ReasonReact.Update({...state, dataSource: source})
    },
  render: self =>
    <Main title="Importer">
      <form>
        <fieldset className="bn">
          <legend className="f3"> {ReasonReact.string("Data Type")} <Help href="/" /> </legend>
          <div className="mt3 ml2">
            <div>
              <input type_="radio" id="csv" name="data_type" value="csv" checked={dataType == CSV} />
              <label className="pl2" htmlFor="csv"> {ReasonReact.string("CSV")} </label>
            </div>
            <div>
              <input type_="radio" id="json" name="data_type" value="json" disabled=true checked={dataType == JSON} />
              <label className="pl2" htmlFor="json"> {ReasonReact.string("JSON (Coming soon)")} </label>
            </div>
          </div>
        </fieldset>
        <fieldset className="bn mt4">
          <legend className="f3"> {ReasonReact.string("Data Origin")} <Help href="/" /> </legend>
          <div className="mt3 ml2">
            <div>
              <input type_="radio" id="url" name="data_origin" value="url" checked={dataOrigin == URL} />
              <label className="pl2" htmlFor="url"> {ReasonReact.string("URL")} </label>
            </div>
            <div>
              <input type_="radio" id="file" name="data_origin" value="file" checked={dataOrigin == FILE} />
              <label className="pl2" htmlFor="file"> {ReasonReact.string("File")} </label>
            </div>
          </div>
          <input type_="text" className="mt3 ml2" id="source" name="data_source" value=dataSource />
        </fieldset>
        <input type_="submit" className="db mt3" name="submit" value="Test Import" id="submit" />
        <input type_="submit" className="db mt3" name="submit" value="Save" id="submit" />
      </form>
    </Main>,
};
