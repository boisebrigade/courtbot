type kinds =
  | CSV
  | JSON;

type origins =
  | URL
  | FILE;

type importer = {
  kind: kinds,
  origin: origins,
  source: string,
  fields: option(array(Fields.field)),
};

type state = {
  dataKind: kinds,
  dataOrigin: origins,
  dataSource: string,
};

type action =
  | UpdateType(kinds)
  | UpdateOrigin(origins)
  | UpdateSource(string);

type destination =
  | CaseNumber
  | LastName
  | FirstName
  | DateAndTime
  | Location
  | Detail
  | County
  | Date
  | Time
  | None;

type kind =
  | String
  | Date;

type format =
  | Format(string)
  | None;

let toKind = kind =>
  switch (kind) {
  | "CSV" => CSV
  | "JSON" => JSON
  | _ => CSV
  };

let toKindType = kind =>
  switch (kind) {
  | "string" => String
  | "date" => Date
  | _ => String
  };

let toOrigin = origin =>
  switch (origin) {
  | "URL" => URL
  | "FILE" => FILE
  | _ => URL
  };

let toDestination = destination =>
  switch (destination) {
  | "case_number" => CaseNumber
  | "last_name" => LastName
  | "first_name" => FirstName
  | "date_and_time" => DateAndTime
  | "location" => Location
  | "detail" => Detail
  | "county" => County
  | "date" => Date
  | "time" => Time
  | _ => None
  };

module GetImporter = [%graphql
  {|
    query GetImporter {
      importer @bsRecord {
        kind @bsDecoder(fn: "toKind")
        origin @bsDecoder(fn: "toOrigin")
        source
        fields {
          index
          pointer
          destination
          kind
          format
        }
      }
    }
  |}
];

module GetImporterQuery = ReasonApollo.CreateQuery(GetImporter);

module Destination = {
  let component = ReasonReact.statelessComponent(__MODULE__);
  let destinations = [
    "",
    "case_number",
    "last_name",
    "first_name",
    "date_and_time",
    "location",
    "detail",
    "county",
    "date",
    "time",
  ];

  let make = (~destination, _children) => {
    ...component,
    render: _self =>
      <select name="destination">
        {
          ReasonReact.array(
            List.map(
              d => <option value=d selected={d == destination}> {ReasonReact.string(d)} </option>,
              destinations,
            )
            |> Array.of_list,
          )
        }
      </select>,
  };
};

module Kind = {
  let component = ReasonReact.statelessComponent(__MODULE__);
  let kinds = ["string", "date"];

  let make = (~kind, _children) => {
    ...component,
    render: _self =>
      <select name="kind">
        {
          ReasonReact.array(
            List.map(
              k => <option value=k selected={k == kind}> {k |> String.capitalize |> ReasonReact.string} </option>,
              kinds,
            )
            |> Array.of_list,
          )
        }
      </select>,
  };
};

module Field = {
  let component = ReasonReact.statelessComponent(__MODULE__);
  let make = (~properties, _children) => {
    ...component,
    render: _self => {
      let source =
        switch (properties##index) {
        | Some(index) => string_of_int(index)
        | None =>
          switch (properties##pointer) {
          | Some(pointer) => pointer
          | None => ""
          }
        };

      let destination =
        switch (properties##destination) {
        | Some(destination) => destination
        | None => ""
        };

      let kind =
        switch (properties##kind) {
        | Some(kind) => kind
        | None => ""
        };

      let format =
        switch (properties##format) {
        | Some(format) => format
        | None => ""
        };

      <tr className="striped--near-white">
        <td className="pv2 ph3 w2 tc"> {ReasonReact.string(source)} </td>
        <td className="pv2 ph3 w5 tc"> <Destination destination /> </td>
        <td className="pv2 ph3 w5 tc"> <Kind kind /> </td>
        <td className="pv2 ph3 w5 tc"> <input type_="text" value=format /> </td>
      </tr>;
    },
  };
};

module FieldMapper = {
  let component = ReasonReact.statelessComponent(__MODULE__);

  let make = (~fields, _children) => {
    ...component,
    render: _self =>
      <Setting title="Field Mapping" help="/">
        <table className="collapse ba br2 b--black-10 pv2 ph3 mt4 bn">
          <tbody className="ml3">
            <tr className="striped--near-white">
              <th className="pv2 ph3 f6 fw6 ttu w2"> {ReasonReact.string("Source")} </th>
              <th className="pv2 ph3 f6 fw6 ttu w5"> {ReasonReact.string("Destination")} </th>
              <th className="pv2 ph3 f6 fw6 ttu w5"> {ReasonReact.string("Type")} </th>
              <th className="pv2 ph3 f6 fw6 ttu w5"> {ReasonReact.string("Format")} </th>
            </tr>
            {
              switch (fields) {
              | Some(fields) =>
                ReasonReact.array(Array.map((field: Fields.field) => <Field key="0" properties=field />, fields))
              | None => ReasonReact.null
              }
            }
          </tbody>
        </table>
      </Setting>,
  };
};

module Configuration = {
  let component = ReasonReact.reducerComponent(__MODULE__);

  let make = (~kind=CSV, ~origin=FILE, ~source="", _children) => {
    ...component,
    initialState: () => {dataKind: kind, dataOrigin: origin, dataSource: source},
    reducer: (action, state) =>
      switch (action) {
      | UpdateType(dataKind) => ReasonReact.Update({...state, dataKind})
      | UpdateOrigin(dataOrigin) => ReasonReact.Update({...state, dataOrigin})
      | UpdateSource(dataSource) => ReasonReact.Update({...state, dataSource})
      },
    render: self =>
      <>
        <Setting title="Data Type" help="/">
          <div className="mt3">
            <div>
              <input
                type_="radio"
                id="csv"
                name="data_type"
                checked={self.state.dataKind == CSV}
                onChange={_e => self.send(UpdateType(CSV))}
              />
              <label className="pl2" htmlFor="csv"> {ReasonReact.string("CSV")} </label>
            </div>
          </div>
          <div>
            <div>
              <input
                type_="radio"
                id="json"
                name="data_type"
                disabled=true
                checked={self.state.dataKind == JSON}
                onChange={_e => self.send(UpdateType(JSON))}
              />
              <label className="pl2" htmlFor="json"> {ReasonReact.string("JSON")} </label>
            </div>
          </div>
        </Setting>
        <Setting title="Data Origin" help="/">
          <div>
            <input
              type_="radio"
              id="url"
              name="data_origin"
              checked={self.state.dataOrigin == URL}
              onChange={_e => self.send(UpdateOrigin(URL))}
            />
            <label className="pl2" htmlFor="url"> {ReasonReact.string("URL")} </label>
          </div>
          <div>
            <input
              type_="radio"
              id="file"
              name="data_origin"
              checked={self.state.dataOrigin == FILE}
              onChange={_e => self.send(UpdateOrigin(FILE))}
            />
            <label className="pl2" htmlFor="file"> {ReasonReact.string("File")} </label>
          </div>
        </Setting>
        <Setting title="Data Source" help="/">
          <input
            type_="text"
            id="source"
            name="data_source"
            className="w5"
            value=source
            onChange={_e => self.send(UpdateSource("csv"))}
          />
        </Setting>
      </>,
  };
};

module Settings = {
  let component = ReasonReact.statelessComponent(__MODULE__);

  let make = (~kind, ~origin, _children) => {
    ...component,
    render: _self =>
      <Setting title="Field Settings" help="/">
        <div>
          <input type_="text" id="delimiter" name="data_origin" className="w1 tc" placeholder="," />
          <label className="pl2" htmlFor="url"> {ReasonReact.string("Delimiter Char")} </label>
        </div>
        <div className="mt3">
          <input type_="checkbox" id="url" name="data_origin" />
          <label className="pl2" htmlFor="url"> {ReasonReact.string("Has Headers")} </label>
        </div>
      </Setting>,
  };
};

let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self => {
    let importer = GetImporter.make();
    <Main title="Importer">
      <GetImporterQuery variables=importer##variables>
        ...{
             ({result}) =>
               switch (result) {
               | Loading => <div> {ReasonReact.string("Loading")} </div>
               | Error(_error) => <div> {ReasonReact.string("Error")} </div>
               | Data(data) =>
                 switch (data##importer) {
                 | Some({origin, kind, source, fields}) =>
                   <form>
                     <Configuration kind origin source />
                     <Settings kind origin />
                     <input type_="submit" className="db mt3 ml3" name="submit" value="Test Import" id="submit" />
                     <FieldMapper fields />
                     <input type_="submit" className="db mt3 ml3" name="submit" value="Save" id="submit" />
                   </form>
                 | None => ReasonReact.null
                 }
               }
           }
      </GetImporterQuery>
    </Main>;
  },
};
