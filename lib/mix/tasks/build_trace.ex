defmodule Mix.Tasks.BuildTrace do
  alias TinyTracer.{DependencyMapping, Model, Trace, TraceFile}
  use Mix.Task

  def run([path]) when is_binary(path) do
    trace =
      case Path.basename(path) do
        "FA" <> _problem -> build_assembly_trace(path)
        "FD" <> _problem -> build_disassembly_trace(path)
        "FR" <> _problem -> build_reassembly_trace(path)
      end
    trace_file_path = TraceFile.path_from_problem(path)
    trace_file_path
    |> Path.dirname
    |> File.mkdir_p
    TraceFile.write(trace_file_path, trace.commands)
  end
  def run(_args) do
    IO.puts "USAGE:  mix build_trace PATH"
  end

  def build_disassembly_trace(path) do
    path
    |> Model.from_file
    |> DependencyMapping.from_model
    |> Trace.from_dependency_mapping
  end

  def build_assembly_trace(path) do
    path
    |> build_disassembly_trace
    |> Trace.reverse
  end

  def build_reassembly_trace(path) do
    {src_path, tgt_path} =
      if String.contains?(path, "src") do
        {path, String.replace(path, "src", "tgt")}
      else
        {String.replace(path, "tgt", "src"), path}
      end
    disassembly_trace = build_disassembly_trace(src_path)
    assembly_trace = build_assembly_trace(tgt_path)
    Trace.combine(disassembly_trace, assembly_trace)
  end
end
