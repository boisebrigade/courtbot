defmodule CourtbotTest.Helper.Configuration do
  alias Courtbot.Configuration

  def boise(),
    do:
      Configuration.changeset(%Configuration{}, %{
        importer: %{
          kind: "csv",
          origin: "file",
          source: "#{File.cwd!()}/test/data/boise.csv",
          delimiter: ",",
          has_headers: true,
          county_duplicates: true,
          field_mapping: [
            %{
              destination: "case_number"
            },
            %{
              destination: "last_name"
            },
            %{
              destination: "first_name"
            },
            %{
              destination: nil
            },
            %{
              destination: nil
            },
            %{
              destination: nil
            },
            %{
              destination: "date",
              kind: "date",
              format: "%-m/%e/%Y"
            },
            %{
              destination: "time",
              kind: "time",
              format: "%-I:%M %p"
            },
            %{
              destination: nil
            },
            %{
              destination: "county"
            }
          ]
        },
        timezone: "America/Boise",
        scheduled: %{
          tasks: [
            %{name: "import", crontab: "0 11 * * *"},
            %{name: "notify", crontab: "0 19 * * *"}
          ]
        },
        locales: %{en: "12083144089"},
        types: [
          %{name: "civil", pattern: "CV"},
          %{name: "criminal", pattern: "CR"}
        ],
        notifications: %{
          queuing: false,
          reminders: [%{hours: 24}]
        },
        variables: [
          %{name: "court_url", value: "https://mycourts.idaho.gov/"}
        ]
      })

  def atlanta(),
    do:
      Configuration.changeset(%Configuration{}, %{
        importer: %{
          kind: "csv",
          origin: "file",
          source: "#{File.cwd!()}/test/data/atlanta.csv",
          delimiter: "|",
          has_headers: true,
          county_duplicates: false,
          field_mapping: [
            %{
              destination: "date",
              kind: "date",
              format: "%-m/%e/%Y"
            },
            %{
              destination: nil
            },
            %{
              destination: nil
            },
            %{
              destination: nil
            },
            %{
              destination: "time",
              kind: "time",
              format: "%-k:%M:%S"
            },
            %{
              destination: "case_number"
            },
            %{
              destination: nil
            },
            %{
              destination: nil
            },
            %{
              destination: nil
            }
          ]
        }
      })

  def anchorage(),
    do:
      Configuration.changeset(%Configuration{}, %{
        importer: %{
          kind: "csv",
          origin: "file",
          source: "#{File.cwd!()}/test/data/anchorage.csv",
          delimiter: ",",
          has_headers: false,
          county_duplicates: false,
          field_mapping: [
            %{
              destination: "date",
              kind: "date",
              format: "%-m/%e/%Y"
            },
            %{
              destination: "last_name"
            },
            %{
              destination: "first_name"
            },
            %{
              destination: nil
            },
            %{
              destination: "location"
            },
            %{
              destination: "time",
              kind: "time",
              format: "%-I:%M %P"
            },
            %{
              destination: "case_number"
            },
            %{
              destination: nil
            },
            %{
              destination: "violation"
            },
            %{
              destination: nil
            }
          ]
        }
      })
end
