end_time = 864000
dt = 1800
period = 91048.6
amplitude = 3548.6
mean_press = 3.7316e5 
rho_seds = 2360 #1800

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 1
  ny = 60#344#3400
  xmin = 0
  xmax = 20
  ymin = -600#-8600#-8500
  ymax = 0
  # bias_y = 0.95
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
  PorousFlowDictator = dictator
  block = 0
  biot_coefficient = 0.9
  multiply_by_density = false
[]

[Variables]
  [disp_x]
    scaling = 1e-10
  []
  [disp_y]
    scaling = 1e-10
  []
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
    expression = 'pp + (-g*rho_f*y)'
    symbol_names = 'pp g rho_f'
    symbol_values = '${mean_press} 9.81 1026'
  []
  [ini_stress_yy]
    # remember this is effective stress
    type = ParsedFunction
    expression = '(rho_s*g - rho_f*g*0.9) * y' 
    symbol_names = 'rho_s rho_f g'
    symbol_values = '${rho_seds} 1026 9.81'
  []
  [cyclic_porepressure]
    type = ParsedFunction
    expression = 'if(t>0, (amp*sin(2*pi*(t/P)))+pp, pp)'
    symbol_names = 'amp P pp'
    symbol_values = '${amplitude} ${period} ${mean_press}'
  []
  [neg_cyclic_porepressure]
    type = ParsedFunction
    expression = '-if(t>0, (amp*sin(2*pi*(t/P)))+pp, pp)'
    symbol_names = 'amp P pp'
    symbol_values = '${amplitude} ${period} ${mean_press}'
  []
  # [cyclic_porepressure]
  #   type = ParsedFunction
  #   expression = 'if(t>0,(f1*cos(((2*pi)/P)*t)-f2*sin(((2*pi)/P)*t))+pp,pp)'
  #   symbol_names = 'P f1 f2 pp'
  #   symbol_values = '91048.6 -1.3816e3 -3.2686e3 ${mean_press}'
  # []
  # [neg_cyclic_porepressure]
  #   type = ParsedFunction
  #   expression = '-if(t>0,(f1*cos(((2*pi)/P)*t)-f2*sin(((2*pi)/P)*t))+pp,pp)'
  #   symbol_names = 'P f1 f2 pp'
  #   symbol_values = '91048.6 -1.3816e3 -3.2686e3 ${mean_press}'
  # []
[]

[BCs]
  # Hydraulic Boundaries
  [pp]
  type = FunctionDirichletBC
  variable = pp
  function = cyclic_porepressure
  boundary = top
  []
  # Mechanical Boundaries
  [no_x_disp]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'left right' # because of 1-element meshing, this fixes u_x=0 everywhere
  []
  [total_stress_at_top]
    type = FunctionNeumannBC
    variable = disp_y
    function = neg_cyclic_porepressure
    boundary = top
  []
  [no_y_disp]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = bottom
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

[PorousFlowBasicTHM]
  coupling_type = HydroMechanical
  displacements = 'disp_x disp_y'
  porepressure = pp
  gravity = '0 -9.81 0'
  fp = the_simple_fluid
  use_displaced_mesh = false
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    bulk_modulus = 3.4e8 # drained bulk modulus
    shear_modulus = 2.2e8 # drained shear modulus
  []
  [strain]
    type = ComputeSmallStrain
    eigenstrain_names = ini_stress
  []
  [stress]
    type = ComputeLinearElasticStress
  []
  [ini_stress]
    type = ComputeEigenstrainFromInitialStress
    initial_stress = '0 0 0  0 ini_stress_yy 0  0 0 0'
    eigenstrain_name = ini_stress
  []
  [porosity]
    type = PorousFlowPorosityConst # only the initial value of this is ever used
    porosity = 0.25
  []
  [biot_modulus]
    type = PorousFlowConstantBiotModulus
    biot_coefficient = 0.9
    fluid_bulk_modulus = 2E9
  []
  [permeability]
    type = PorousFlowPermeabilityConst
    # permeability = '1.8e-10 0 0   0 1.8e-10 0   0 0 1.8e-10'
    permeability = '4e-14 0 0   0 4e-14 0   0 0 4e-14'
  []
  [density]
    type = GenericConstantMaterial
    prop_names = density
    prop_values = ${rho_seds}
  []
[]

[Postprocessors]
  [p0]
    type = PointValue
    outputs = csv
    point = '0 0 0'
    variable = pp
  []
  [uz0]
    type = PointValue
    outputs = csv
    point = '0 0 0'
    variable = disp_y
  []
[]

[VectorPostprocessors]
  [depth_pp]
    type = LineValueSampler
    variable = pp
    start_point = '0 0 0'
    end_point = '0 -100 0'
    num_points = 100
    sort_by = y
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
  # line_search = none
  solve_type = Newton
  [TimeSteppers]
    active = adaptive
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
  exodus = false
  csv = true
  file_base = './out_files/mbari'
[]
