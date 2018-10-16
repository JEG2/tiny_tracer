defmodule TinyTracer.Coord do
  def mlen({x, y, z}) do
    abs(x) + abs(y) + abs(z)
  end

  def closest(xyz, voxels) do
    voxels
    |> Enum.map(fn voxel -> {xyz |> to_d(voxel) |> mlen, voxel} end)
    |> Enum.sort
    |> hd
    |> elem(1)
  end

  def near({x, y, z}, resolution) do
    [
      {x - 1, y - 1, z    },
      {x - 1, y    , z - 1},
      {x - 1, y    , z    },
      {x - 1, y    , z + 1},
      {x - 1, y + 1, z    },
      {x    , y - 1, z - 1},
      {x    , y - 1, z    },
      {x    , y - 1, z + 1},
      {x    , y    , z - 1},
      {x    , y    , z + 1},
      {x    , y + 1, z - 1},
      {x    , y + 1, z    },
      {x    , y + 1, z + 1},
      {x + 1, y - 1, z    },
      {x + 1, y    , z - 1},
      {x + 1, y    , z    },
      {x + 1, y    , z + 1},
      {x + 1, y + 1, z    }
    ]
    |> Enum.filter(&valid?(&1, resolution))
  end

  def adjacent({x, y, z}, resolution) do
    [
      {x - 1, y    , z    },
      {x    , y - 1, z    },
      {x    , y    , z - 1},
      {x    , y    , z + 1},
      {x    , y + 1, z    },
      {x + 1, y    , z    }
    ]
    |> Enum.filter(&valid?(&1, resolution))
  end

  def to_d({src_x, src_y, src_z}, {dst_x, dst_y, dst_z}) do
    {dst_x - src_x, dst_y - src_y, dst_z - src_z}
  end

  def valid?({x, y, z}, resolution) do
    x >= 0 and x < resolution and
    y >= 0 and y < resolution and
    z >= 0 and z < resolution
  end
end
