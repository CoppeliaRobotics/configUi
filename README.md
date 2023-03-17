# ConfigUI 2

A library for CoppeliaSim models' configuration.

### Compiling

1. Install required packages for simStubsGen: see simStubsGen's [README](https://github.com/CoppeliaRobotics/include/blob/master/simStubsGen/README.md)
2. Checkout, compile and install into CoppeliaSim:
```sh
$ cd path/to/CoppeliaSim/programming
$ git clone https://github.com/CoppeliaRobotics/configUi-2.git
$ cd configUi-2
$ git checkout coppeliasim-v4.5.0-rev0
$ mkdir -p build && cd build
$ cmake -DCMAKE_BUILD_TYPE=Release ..
$ cmake --build .
$ cmake --install .
```

NOTE: replace `coppeliasim-v4.5.0-rev0` with the actual CoppeliaSim version you have.

### Usage

Create a `ConfigUI` object with parameters:
- a string identifying the model type (e.g. `"MyRobot"`),
- a table with schema definition (see below),
- a function that is called with a config parameter (table) when the configuration is changed, which can be used to generate or configure the model.

### Schema

Schema is a table of element schemas, in the form:

```
{
    elementName1={
        ...
    },
    elementName2={
        ...
    },
    ...
}
```

where `elementNameN` is the name of the field which will be used also in the config table.

### Element schema

The valid fields of an element schema are:

- `name`: (mandatory) a string with the description of the field (i.e. for the UI label);
- `type`: (mandatory) a string with the type of the field (valid types are: int, float, bool, string, color, choices, callback);
- `default`: the default value of the field;
- `minimum`: the minimum value (optional, only for types int and float);
- `maximum`: the maximum value (optional, only for types int and float);
- `step`: the step value (optional, only for types int and float);
- `choices`: the option values for types radio and combo;
- `labels`: labels to use in place of the choices above;
- `ui`: a table of parameters for the UI:
    - `order`: an int to provide an ordering of fields;
    - `group`: an int to provide a visual grouping of fields;
    - `col`: an int to arrange fields in multiple columns within a group;
    - `tab`: a string to arrange fields in multiple tab pages;
    - `control`: manually specify a control when a type (e.g. int, float, choices) is supported by multiple controls (e.g. spinbox and slider for numeric types, radio and combo for choices type).

### Example

Here's a complete example:

```lua
require'configUi-2'

schema={
    a={
        type='int',
        name='A',
        minimum=0,
        maximum=10,
        ui={order=1,control='spinbox',},
    },
    b={
        type='string',
        name='B',
        ui={order=2,},
    }
}

function gen(cfg)
    print('Config has changed:')
    print(cfg)
end

configUi=ConfigUI('myModelType',schema,gen)
```
