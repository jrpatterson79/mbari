end_time = 864000
dt = 1800
rho_seds = 1800
mean_press = 3.7316e5

[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 1
  ny = 1
  nz = 250
  xmin = 0
  xmax = 50
  ymin = 0
  ymax = 50
  zmin = -500
  zmax = 0
  # bias_z = 0.95
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
  PorousFlowDictator = dictator
  block = 0
  biot_coefficient = 0.6
  multiply_by_density = false
[]

[Variables]
  [disp_x]
    scaling = 1e-10
  []
  [disp_y]
    scaling = 1e-10
  []
  [disp_z]
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
    expression = 'pp + (-9.81*1026*z)'
    symbol_names = 'pp'
    symbol_values = '${mean_press}'
  []
  [ini_stress_zz]
    # remember this is effective stress
    type = ParsedFunction
    expression = '(rho_s*g - rho_f*g*0.6) * z' 
    symbol_names = 'rho_s g rho_f pp'
    symbol_values = '${rho_seds} 9.81 1026 ${mean_press}'
  []
  [cyclic_porepressure]
    type = ParsedFunction
    expression = 'if(t>0,(f1*cos(((2*pi)/P1)*t)-f2*sin(((2*pi)/P1)*t))+pp,pp)'
    symbol_names = 'P1 f1 f2 pp'
    symbol_values = '44739.2 3.6010e3 -462.1223 ${mean_press}'
  []
  [neg_cyclic_porepressure]
    type = ParsedFunction
    expression = '-if(t>0,(f1*cos(((2*pi)/P1)*t)-f2*sin(((2*pi)/P1)*t))+pp,pp)'
    symbol_names = 'P1 f1 f2 pp'
    symbol_values = '44739.2 3.6010e3 -462.1223 ${mean_press}'
  []
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
  # Mechanical Boundaries
  [no_x_disp]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'bottom top' # because of 1-element meshing, this fixes u_x=0 everywhere
  []
  [no_y_disp]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'bottom top' # because of 1-element meshing, this fixes u_y=0 everywhere
  []
  [no_z_disp_at_bottom]
    type = DirichletBC
    variable = disp_z
    value = 0
    boundary = back
  []
  [total_stress_at_top]
    type = FunctionNeumannBC
    variable = disp_z
    function = neg_cyclic_porepressure
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

[PorousFlowBasicTHM]
  coupling_type = HydroMechanical
  displacements = 'disp_x disp_y disp_z'
  porepressure = pp
  gravity = '0 0 -9.81'
  fp = the_simple_fluid
  use_displaced_mesh = false
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    shear_modulus = 6.5e8 # drained bulk modulus
    bulk_modulus = 4.4e8
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
    initial_stress = '0 0 0  0 0 0  0 0 ini_stress_zz'
    eigenstrain_name = ini_stress
  []
  [porosity]
    type = PorousFlowPorosityConst # only the initial value of this is ever used
    porosity = 0.5
  []
  [biot_modulus]
    type = PorousFlowConstantBiotModulus
    biot_coefficient = 0.6
    fluid_bulk_modulus = 2E9
  []
  [permeability]
    type = PorousFlowPermeabilityConst
    permeability = '1.8e-10 0 0   0 1.8e-10 0   0 0 1.8e-10'
    # permeability = '3.75e-15 0 0   0 3.75e-15 0   0 0 3.75e-15'
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
    variable = disp_z
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
  # line_search = none
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
  start_time = -${dt} # so postprocessors get recorded correctly at t=0
  end_time = ${end_time}
  nl_abs_tol = 1e-8
  nl_rel_tol = 1E-10
[]

[Outputs]
  exodus = true
  csv = true
  file_base = './out_files/mbari'
[]
