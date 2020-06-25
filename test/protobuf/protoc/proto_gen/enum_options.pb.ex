defmodule Ext.MyPetIs do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  @type t ::
          integer | :MY_PET_IS_A_CAT | :MY_PET_IS_A_BIRD | :MY_PET_IS_A_DOG | :MY_PET_IS_A_UNKNOWN
  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.EnumDescriptorProto.decode(
      <<10, 7, 77, 121, 80, 101, 116, 73, 115, 18, 19, 10, 15, 77, 89, 95, 80, 69, 84, 95, 73, 83,
        95, 65, 95, 67, 65, 84, 16, 0, 18, 20, 10, 16, 77, 89, 95, 80, 69, 84, 95, 73, 83, 95, 65,
        95, 66, 73, 82, 68, 16, 1, 18, 19, 10, 15, 77, 89, 95, 80, 69, 84, 95, 73, 83, 95, 65, 95,
        68, 79, 71, 16, 2, 18, 23, 10, 19, 77, 89, 95, 80, 69, 84, 95, 73, 83, 95, 65, 95, 85, 78,
        75, 78, 79, 87, 78, 16, 3, 26, 8, 24, 0, 250, 222, 31, 2, 24, 1>>
    )
  end

  field :MY_PET_IS_A_CAT, 0
  field :MY_PET_IS_A_BIRD, 1
  field :MY_PET_IS_A_DOG, 2
  field :MY_PET_IS_A_UNKNOWN, 3
end

defmodule Ext.MyBetIsA do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  @type t ::
          integer
          | :MY_BET_IS_A_CAT
          | :MY_BET_IS_A_BIRD
          | :MY_BET_IS_A_DOG
          | :MY_BET_IS_A_UNKNOWN
          | :HORSE
  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.EnumDescriptorProto.decode(
      <<10, 8, 77, 121, 66, 101, 116, 73, 115, 65, 18, 19, 10, 15, 77, 89, 95, 66, 69, 84, 95, 73,
        83, 95, 65, 95, 67, 65, 84, 16, 0, 18, 20, 10, 16, 77, 89, 95, 66, 69, 84, 95, 73, 83, 95,
        65, 95, 66, 73, 82, 68, 16, 1, 18, 19, 10, 15, 77, 89, 95, 66, 69, 84, 95, 73, 83, 95, 65,
        95, 68, 79, 71, 16, 2, 18, 23, 10, 19, 77, 89, 95, 66, 69, 84, 95, 73, 83, 95, 65, 95, 85,
        78, 75, 78, 79, 87, 78, 16, 3, 18, 9, 10, 5, 72, 79, 82, 83, 69, 16, 4, 26, 8, 24, 0, 250,
        222, 31, 2, 24, 1>>
    )
  end

  field :MY_BET_IS_A_CAT, 0
  field :MY_BET_IS_A_BIRD, 1
  field :MY_BET_IS_A_DOG, 2
  field :MY_BET_IS_A_UNKNOWN, 3
  field :HORSE, 4
end

defmodule Ext.TrafficFlight do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  @type t ::
          integer
          | :TRAFFIC_FLIGHT_COLOR_INVALID
          | :TRAFFIC_FLIGHT_COLOR_UNSET
          | :TRAFFIC_FLIGHT_COLOR_GREEN
          | :TRAFFIC_FLIGHT_COLOR_YELLOW
          | :TRAFFIC_FLIGHT_COLOR_RED
  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.EnumDescriptorProto.decode(
      <<10, 13, 84, 114, 97, 102, 102, 105, 99, 70, 108, 105, 103, 104, 116, 18, 32, 10, 28, 84,
        82, 65, 70, 70, 73, 67, 95, 70, 76, 73, 71, 72, 84, 95, 67, 79, 76, 79, 82, 95, 73, 78,
        86, 65, 76, 73, 68, 16, 0, 18, 30, 10, 26, 84, 82, 65, 70, 70, 73, 67, 95, 70, 76, 73, 71,
        72, 84, 95, 67, 79, 76, 79, 82, 95, 85, 78, 83, 69, 84, 16, 1, 18, 30, 10, 26, 84, 82, 65,
        70, 70, 73, 67, 95, 70, 76, 73, 71, 72, 84, 95, 67, 79, 76, 79, 82, 95, 71, 82, 69, 69,
        78, 16, 2, 18, 31, 10, 27, 84, 82, 65, 70, 70, 73, 67, 95, 70, 76, 73, 71, 72, 84, 95, 67,
        79, 76, 79, 82, 95, 89, 69, 76, 76, 79, 87, 16, 3, 18, 28, 10, 24, 84, 82, 65, 70, 70, 73,
        67, 95, 70, 76, 73, 71, 72, 84, 95, 67, 79, 76, 79, 82, 95, 82, 69, 68, 16, 4, 26, 8, 24,
        0, 250, 222, 31, 2, 8, 1>>
    )
  end

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

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 15, 69, 110, 117, 109, 84, 101, 115, 116, 77, 101, 115, 115, 97, 103, 101, 18, 30, 10,
        3, 112, 101, 116, 24, 1, 32, 1, 40, 14, 50, 12, 46, 101, 120, 116, 46, 77, 121, 80, 101,
        116, 73, 115, 82, 3, 112, 101, 116, 18, 31, 10, 3, 98, 101, 116, 24, 2, 32, 1, 40, 14, 50,
        13, 46, 101, 120, 116, 46, 77, 121, 66, 101, 116, 73, 115, 65, 82, 3, 98, 101, 116, 18,
        53, 10, 12, 102, 108, 105, 103, 104, 116, 95, 99, 111, 108, 111, 114, 24, 3, 32, 1, 40,
        14, 50, 18, 46, 101, 120, 116, 46, 84, 114, 97, 102, 102, 105, 99, 70, 108, 105, 103, 104,
        116, 82, 11, 102, 108, 105, 103, 104, 116, 67, 111, 108, 111, 114, 18, 44, 10, 5, 99, 111,
        108, 111, 114, 24, 4, 32, 1, 40, 14, 50, 22, 46, 101, 120, 116, 46, 84, 114, 97, 102, 102,
        105, 99, 76, 105, 103, 104, 116, 67, 111, 108, 111, 114, 82, 5, 99, 111, 108, 111, 114,
        18, 72, 10, 8, 99, 111, 108, 111, 114, 95, 108, 99, 24, 5, 32, 1, 40, 14, 50, 22, 46, 101,
        120, 116, 46, 84, 114, 97, 102, 102, 105, 99, 76, 105, 103, 104, 116, 67, 111, 108, 111,
        114, 66, 21, 24, 0, 40, 0, 80, 0, 250, 222, 31, 11, 18, 9, 108, 111, 119, 101, 114, 99,
        97, 115, 101, 82, 7, 99, 111, 108, 111, 114, 76, 99, 18, 75, 10, 10, 99, 111, 108, 111,
        114, 95, 100, 101, 112, 114, 24, 6, 32, 1, 40, 14, 50, 22, 46, 101, 120, 116, 46, 84, 114,
        97, 102, 102, 105, 99, 76, 105, 103, 104, 116, 67, 111, 108, 111, 114, 66, 20, 24, 0, 40,
        0, 80, 0, 250, 222, 31, 10, 18, 8, 100, 101, 112, 114, 101, 102, 105, 120, 82, 9, 99, 111,
        108, 111, 114, 68, 101, 112, 114, 18, 74, 10, 10, 99, 111, 108, 111, 114, 95, 97, 116,
        111, 109, 24, 7, 32, 1, 40, 14, 50, 22, 46, 101, 120, 116, 46, 84, 114, 97, 102, 102, 105,
        99, 76, 105, 103, 104, 116, 67, 111, 108, 111, 114, 66, 19, 24, 0, 40, 0, 80, 0, 250, 222,
        31, 9, 18, 7, 97, 116, 111, 109, 105, 122, 101, 82, 9, 99, 111, 108, 111, 114, 65, 116,
        111, 109>>
    )
  end

  field :pet, 1, type: Ext.MyPetIs, enum: true
  field :bet, 2, type: Ext.MyBetIsA, enum: true
  field :flight_color, 3, type: Ext.TrafficFlight, enum: true
  field :color, 4, type: Ext.TrafficLightColor, enum: true
  field :color_lc, 5, type: Ext.TrafficLightColor, enum: true, options: [enum: "lowercase"]
  field :color_depr, 6, type: Ext.TrafficLightColor, enum: true, options: [enum: "deprefix"]
  field :color_atom, 7, type: Ext.TrafficLightColor, enum: true, options: [enum: "atomize"]
end
