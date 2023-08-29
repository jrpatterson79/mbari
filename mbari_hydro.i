end_time = 410400
dt = 3600
mean_press = 3.7316e5

[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 1
  ny = 1
  nz = 500
  xmin = 0
  xmax = 10
  ymin = 0
  ymax = 10
  zmin = -500
  zmax = 0
  bias_z = 0.95
[]

[GlobalParams]
  PorousFlowDictator = dictator
  block = 0
  biot_coefficient = 1
  multiply_by_density = false
[]

[Variables]
  [pp]
  []
[]

[ICs]
  [pp_init]
    type = FunctionIC
    variable = pp
    function = hydrostatic
  []
[]

[Functions]
  [hydrostatic]
    type = ParsedFunction
    expression = 'mean_press + (-9.81*1026*z)'
    symbol_names = 'mean_press'
    symbol_values = '${mean_press}'
  []
  [cyclic_porepressure]
    type = ParsedFunction
    expression = 'if(t>0,((f1*cos(((2*pi)/P1)*t)-f2*sin(((2*pi)/P1)*t))+(f3*cos(((2*pi)/P2)*t)-f4*sin(((2*pi)/P2)*t)))+mean_press,mean_press)'
    symbol_names = 'P1 P2 f1 f2 f3 f4 mean_press'
    symbol_values = '44739.2 91048.6 3.6010e3 -462.1223 -1.3816e3 -3.2686e3 ${mean_press}'
  []
#   [neg_cyclic_porepressure]
#     type = ParsedFunction
#     expression = '-if(t>0,((f1*cos(((2*pi)/P1)*t)-f2*sin(((2*pi)/P1)*t))+(f3*cos(((2*pi)/P2)*t)-f4*sin(((2*pi)/P2)*t)))+mean_press,mean_press)'
#     symbol_names = 'P1 P2 f1 f2 f3 f4 mean_press'
#     symbol_values = '44739.2 91048.6 3.6333e3 -465.7120 -1.3937e3 -3.2978e3 ${mean_press}'
#   []
[]

[BCs]
  # zmin is called 'back'
  # zmax is called 'front'
  # ymin is called 'bottom'
  # ymax is called 'top'
  # xmin is called 'left'
  # xmax is called 'right'
  # Hydraulic Boundaries
  [pp]
  type = FunctionDirichletBC
  variable = pp
  function = cyclic_porepressure
  boundary = front
  []
[]

[FluidProperties]
  [the_simple_fluid]
    type = SimpleFluidProperties
    thermal_expansion = 0.0
    bulk_modulus = 2E9
    viscosity = 1.26e-3
    density0 = 1026
  []
[]

[PorousFlowFullySaturated]
  coupling_type = Hydro
  porepressure = pp
  gravity = '0 0 -9.81'
  fp = the_simple_fluid
[]

[Materials]
  [porosity]
    type = PorousFlowPorosityConst # only the initial value of this is ever used
    porosity = 0.5
  []
  [biot_modulus]
    type = PorousFlowConstantBiotModulus
    biot_coefficient = 1
    fluid_bulk_modulus = 2E9
  []
  [permeability]
    type = PorousFlowPermeabilityConst
    permeability = '1.8e-10 0 0   0 1.8e-10 0   0 0 1.8e-10'
    # permeability = '3.75e-15 0 0   0 3.75e-15 0   0 0 3.75e-15'
  []
[]

[Postprocessors]
  [p0]
    type = PointValue
    outputs = csv
    point = '0 0 0'
    variable = pp
  []
  [p100]
    type = PointValue
    outputs = csv
    point = '0 0 -100'
    variable = pp
  []
[]

[VectorPostprocessors]
  [depth_pp]
    type = LineValueSampler
    variable = pp
    start_point = '0 0 0'
    end_point = '0 0 -300'
    num_points = 300
    sort_by = z
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
 
[Preconditioning]
  [andy]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  line_search = none
  solve_type = Newton
  [TimeSteppers]
    active = constant
    [constant]
      type = ConstantDT
      dt = ${dt}
    []
    [adaptive]
      type = IterationAdaptiveDT
      dt = ${dt}
      growth_factor = 1.05
    []
  []
  dtmax = 3600
  start_time = -${dt} # so postprocessors get recorded correctly at t=0
  end_time = ${end_time}
  nl_abs_tol = 1e-8
  nl_rel_tol = 1E-10
[]

[Outputs]
  exodus = true
  csv = true
  file_base = './out_files/mbari_hydro'
[]
