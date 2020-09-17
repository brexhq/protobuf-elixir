defmodule Ext.MyPetIs do
  @moduledoc false
  use Protobuf, custom_field_options?: true, enum: true, syntax: :proto3

  @type t :: integer | :A_CAT | :A_BIRD | :A_DOG | :A_UNKNOWN

  field :MY_PET_IS_A_CAT, 0
  field :MY_PET_IS_A_BIRD, 1
  field :MY_PET_IS_A_DOG, 2
  field :MY_PET_IS_A_UNKNOWN, 3
end

defmodule Ext.MyBetIsA do
  @moduledoc false
  use Protobuf, custom_field_options?: true, enum: true, syntax: :proto3

  @type t :: integer | :CAT | :BIRD | :DOG | :UNKNOWN | :HORSE

  field :MY_BET_IS_A_CAT, 0
  field :MY_BET_IS_A_BIRD, 1
  field :MY_BET_IS_A_DOG, 2
  field :MY_BET_IS_A_UNKNOWN, 3
  field :HORSE, 4
end

defmodule Ext.TrafficFlight do
  @moduledoc false
  use Protobuf, custom_field_options?: true, enum: true, syntax: :proto3

  @type t :: integer | :color_invalid | :color_unset | :color_green | :color_yellow | :color_red

  field :TRAFFIC_FLIGHT_COLOR_INVALID, 0
  field :TRAFFIC_FLIGHT_COLOR_UNSET, 1
  field :TRAFFIC_FLIGHT_COLOR_GREEN, 2
  field :TRAFFIC_FLIGHT_COLOR_YELLOW, 3
  field :TRAFFIC_FLIGHT_COLOR_RED, 4
end

defmodule Ext.EnumTestMessage do
  @moduledoc false
  use Protobuf, custom_field_options?: true, syntax: :proto3

  @type t :: %__MODULE__{
          pet: Ext.MyPetIs.t(),
          bet: Ext.MyBetIsA.t(),
          flight_color: Ext.TrafficFlight.t(),
          color: Ext.TrafficLightColor.t(),
          color_lc: Ext.TrafficLightColor.t(),
          color_depr: Ext.TrafficLightColor.t(),
          color_atom: Ext.TrafficLightColor.t()
        }
  defstruct [:pet, :bet, :flight_color, :color, :color_lc, :color_depr, :color_atom]

  field :pet, 1, type: Ext.MyPetIs, enum: true
  field :bet, 2, type: Ext.MyBetIsA, enum: true
  field :flight_color, 3, type: Ext.TrafficFlight, enum: true, json_name: "flightColor"
  field :color, 4, type: Ext.TrafficLightColor, enum: true

  field :color_lc, 5,
    type: Ext.TrafficLightColor,
    enum: true,
    json_name: "colorLc",
    options: [enum: "lowercase"]

  field :color_depr, 6,
    type: Ext.TrafficLightColor,
    enum: true,
    json_name: "colorDepr",
    options: [enum: "deprefix"]

  field :color_atom, 7,
    type: Ext.TrafficLightColor,
    enum: true,
    json_name: "colorAtom",
    options: [enum: "atomize"]
end
