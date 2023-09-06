# A 10m x 10m "column" of height 100m is subjected to cyclic pressure at its top
# Assumptions:
# the boundaries are impermeable, except the top boundary
# only vertical displacement is allowed
# the atmospheric pressure sets the total stress at the top of the model
# rho_seds = 2500
# mean_press = 1000

[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 1
  ny = 1
  nz = 10
  xmin = 0
  xmax = 10
  ymin = 0
  ymax = 10
  zmin = -100
  zmax = 0
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
  []
  [disp_y]
  []
  [disp_z]
  []
  [pp]
    scaling = 1E10
  []
[]

[ICs]
  [porepressure]
    type = FunctionIC
    variable = pp
    function = '-10000*z'#hydrostatic  # approximately correct
  []
[]

[Functions]
  [ini_stress_zz]
    type = ParsedFunction
    expression = '(25000 - 0.6*10000)*z' # remember this is effective stress
  []
  [cyclic_porepressure]
    type = ParsedFunction
    expression = 'if(t>0,5000 * sin(2 * pi * t / 3600.0 / 24.0),0)'
  []
  [neg_cyclic_porepressure]
    type = ParsedFunction
    expression = '-if(t>0,5000 * sin(2 * pi * t / 3600.0 / 24.0),0)'
  []
[]
# [Functions]
#   [hydrostatic]
#     type = ParsedFunction
#     expression = 'mean_press + (-g*rho_f*z)'
#     symbol_names = 'mean_press g rho_f'
#     symbol_values = '${mean_press} 9.81 1026'
#   []
#   [ini_stress_zz]
#     # remember this is effective stress
#     type = ParsedFunction
#     expression = '((rho_s * g) - (0.6*g*rho_f))*z'
#     symbol_names = 'rho_s g rho_f'
#     symbol_values = '${rho_seds} 9.81 1026'
#   []
#   [cyclic_porepressure]
#     type = ParsedFunction
#     expression = 'if(t>0,((f1*cos(((2*pi)/P1)*t)-f2*sin(((2*pi)/P1)*t))+(f3*cos(((2*pi)/P2)*t)-f4*sin(((2*pi)/P2)*t)))+mean_press,mean_press)'
#     symbol_names = 'P1 P2 f1 f2 f3 f4 mean_press'
#     symbol_values = '44739.2 91048.6 3.6010e3 -462.1223 -1.3816e3 -3.2686e3 ${mean_press}'
#   []
#   [neg_cyclic_porepressure]
#     type = ParsedFunction
#     expression = '-if(t>0,((f1*cos(((2*pi)/P1)*t)-f2*sin(((2*pi)/P1)*t))+(f3*cos(((2*pi)/P2)*t)-f4*sin(((2*pi)/P2)*t)))+mean_press,mean_press)'
#     symbol_names = 'P1 P2 f1 f2 f3 f4 mean_press'
#     symbol_values = '44739.2 91048.6 3.6333e3 -465.7120 -1.3937e3 -3.2978e3 ${mean_press}'
#   []
# []

[BCs]
  # zmin is called 'back'
  # zmax is called 'front'
  # ymin is called 'bottom'
  # ymax is called 'top'
  # xmin is called 'left'
  # xmax is called 'right'
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
  [pp]
    type = FunctionDirichletBC
    variable = pp
    function = cyclic_porepressure
    boundary = front
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
    viscosity = 1E-3
    density0 = 1000.0
  []
[]

[PorousFlowBasicTHM]
  coupling_type = HydroMechanical
  displacements = 'disp_x disp_y disp_z'
  porepressure = pp
  gravity = '0 0 -10'
  fp = the_simple_fluid
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    bulk_modulus = 10.0E9 # drained bulk modulus
    poissons_ratio = 0.25
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
    porosity = 0.1
  []
  [biot_modulus]
    type = PorousFlowConstantBiotModulus
    solid_bulk_compliance = 1E-10
    fluid_bulk_modulus = 2E9
  []
  [permeability]
    type = PorousFlowPermeabilityConst
    permeability = '1E-12 0 0   0 1E-12 0   0 0 1E-14'
  []
  [density]
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 2500.0
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
    end_point = '0 0 -100'
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
  solve_type = Newton
  start_time = -3600 # so postprocessors get recorded correctly at t=0
  dt = 3600
  end_time = 864000
  nl_abs_tol = 5E-7
  nl_rel_tol = 1E-10
[]

[Outputs]
  csv = true
  file_base = './out_files/mbari'
[]