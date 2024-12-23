import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

pub type Circuit {
  Circuit(wires: List(Wire))
}

pub type Operation {
  And
  Or
  Xor
}

pub type Wire {
  Wire(
    id: String,
    value: Option(Bool),
    sources: List(String),
    operation: Option(Operation),
  )
}

fn parse_wire(wire_input: String) {
  case string.split(wire_input, ": ") {
    [id, value] -> Ok(Wire(id, Some(value == "1"), [], None))
    _ -> Error("Unable to parse wire: " <> wire_input)
  }
}

fn string_to_operation(op_input: String) {
  case op_input {
    "AND" -> Some(And)
    "OR" -> Some(Or)
    "XOR" -> Some(Xor)
    _ -> None
  }
}

fn parse_connection_sources(source_input: String) {
  case string.split(source_input, " ") {
    [source1, op, source2] -> Ok(#([source1, source2], string_to_operation(op)))
    _ -> Error("Unable to parse connection sources: " <> source_input)
  }
}

fn parse_connection(connection_input: String) {
  case string.split(connection_input, " -> ") {
    [srcs, id] ->
      parse_connection_sources(srcs)
      |> result.map(fn(parse_result) {
        let #(sources, op) = parse_result
        Wire(id, None, sources, op)
      })
    _ -> Error("Unable to parse connection: " <> connection_input)
  }
}

fn parse_wires(wires_input: String, connections_input: String) {
  let initial_wires =
    string.split(wires_input, "\n")
    |> list.map(parse_wire)
    |> result.all

  let undefined_wires =
    string.split(connections_input, "\n")
    |> list.filter(fn(s) { string.length(s) > 0 })
    |> list.map(parse_connection)
    |> result.all

  result.all([initial_wires, undefined_wires])
  |> result.map(list.flatten)
}

fn create_circuit(wires) {
  case wires {
    Ok(wires) -> Ok(Circuit(wires))
    Error(e) -> Error(e)
  }
}

fn compute_wire(circuit: Circuit, w: Wire) {
  let sources =
    w.sources
    |> list.map(wire(circuit, _))
    |> result.all
    |> result.map(fn(l) { list.map(l, fn(wi) { wi.value }) })
  case sources, w.operation {
    Ok([None, _]), _ -> w
    Ok([_, None]), _ -> w
    Ok([s1, s2]), Some(op) ->
      case op {
        And ->
          Wire(
            ..w,
            value: Some(option.unwrap(s1, False) && option.unwrap(s2, False)),
          )
        Or ->
          Wire(
            ..w,
            value: Some(option.unwrap(s1, False) || option.unwrap(s2, False)),
          )
        Xor ->
          Wire(
            ..w,
            value: Some(bool.exclusive_or(
              option.unwrap(s1, False),
              option.unwrap(s2, False),
            )),
          )
      }
    _, _ -> w
  }
}

pub fn parse_circuit(input: String) {
  case string.split(input, "\n\n") {
    [wires_input, connections_input] ->
      create_circuit(parse_wires(wires_input, connections_input))
    _ -> Error("Unable to parse circuit: " <> input)
  }
}

pub fn wire(circuit: Circuit, wire_id: String) {
  list.find(circuit.wires, fn(w) { w.id == wire_id })
}

fn is_complete(circuit: Circuit) {
  circuit.wires
  |> list.all(fn(w) { option.is_some(w.value) })
}

fn output_value(circuit: Circuit) {
  circuit.wires
  |> list.filter(fn(w) {
    string.starts_with(w.id, "z") && option.unwrap(w.value, False)
  })
  |> list.map(fn(w) {
    string.drop_start(w.id, 1)
    |> int.parse
    |> result.map(int.to_float)
    |> result.map(int.power(2, _))
    |> result.flatten
    |> result.map(float.truncate)
  })
  |> result.all
  |> result.map(int.sum)
}

pub fn output(circuit: Circuit) {
  case is_complete(circuit) {
    True -> output_value(circuit)
    False ->
      output(Circuit(
        circuit.wires
        |> list.map(compute_wire(circuit, _)),
      ))
  }
}
