#!/usr/bin/env python3
"""Render the corrected package geometry with cutaway detail views (VTK)."""
from pathlib import Path
import numpy as np
import vtk
from vtk.util.numpy_support import numpy_to_vtk
from yapcad.package import PackageManifest
from yapcad.brep import brep_from_solid

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / 'build/yaprover-0.1.0.ycpkg'
OUTPUT = ROOT / 'renders/yapRover_geometry_updates.png'
manifest = PackageManifest.load(PACKAGE)
instances = {i['id']: i for i in manifest.data['instances']}
cache = {}
BG = (0.95, 0.965, 0.98)
INK = (0.10, 0.16, 0.22)
CYAN = (0.08, 0.53, 0.66)
ORANGE = (0.98, 0.43, 0.12)
STEEL = (0.57, 0.64, 0.70)


def mesh(name):
    component = instances[name]['component']
    if component not in cache:
        solid = manifest.load_component_geometry(component)[0]
        surface = brep_from_solid(solid).tessellate(deflection=0.2)
        points = vtk.vtkPoints()
        points.SetData(numpy_to_vtk(np.asarray(surface[1])[:, :3].copy(), deep=True))
        cells = vtk.vtkCellArray()
        for tri in surface[3]:
            cells.InsertNextCell(3)
            for index in tri:
                cells.InsertCellPoint(int(index))
        poly = vtk.vtkPolyData()
        poly.SetPoints(points)
        poly.SetPolys(cells)
        cache[component] = poly
    return cache[component]


def actor(renderer, name, color, positioned=False, planes=(), keyways=False):
    poly = mesh(name)
    if planes:
        collection = vtk.vtkPlaneCollection()
        for origin, normal in planes:
            plane = vtk.vtkPlane(); plane.SetOrigin(*origin); plane.SetNormal(*normal)
            collection.AddItem(plane)
        clip = vtk.vtkClipClosedSurface(); clip.SetInputData(poly)
        clip.SetClippingPlanes(collection); clip.GenerateFacesOn(); clip.Update()
        poly = clip.GetOutput()
    normals = vtk.vtkPolyDataNormals(); normals.SetInputData(poly)
    normals.SetFeatureAngle(40); normals.SplittingOn(); normals.Update()
    poly = normals.GetOutput()
    if keyways:
        colors = vtk.vtkUnsignedCharArray(); colors.SetNumberOfComponents(3)
        for i in range(poly.GetNumberOfCells()):
            cell = poly.GetCell(i)
            points = np.array([poly.GetPoint(cell.GetPointId(j)) for j in range(cell.GetNumberOfPoints())])
            x,y,z = points.mean(axis=0)
            slot = abs(x) <= 1.03 and z >= 2.74 and ((-57.5 <= y <= -43) or (-144 <= y <= -133.5))
            colors.InsertNextTuple3(*[int(c*255) for c in (ORANGE if slot else color)])
        poly.GetCellData().SetScalars(colors)
    mapper = vtk.vtkPolyDataMapper(); mapper.SetInputData(poly)
    if not keyways:
        mapper.ScalarVisibilityOff()
    obj = vtk.vtkActor(); obj.SetMapper(mapper)
    obj.GetProperty().SetColor(*color); obj.GetProperty().SetInterpolationToPhong()
    obj.GetProperty().SetAmbient(0.25); obj.GetProperty().SetDiffuse(0.75)
    obj.GetProperty().SetSpecular(0.2); obj.GetProperty().SetSpecularPower(35)
    if positioned:
        matrix = vtk.vtkMatrix4x4()
        for row in range(4):
            for col in range(4):
                matrix.SetElement(row,col,instances[name]['transform'][row][col])
        obj.SetUserMatrix(matrix)
    renderer.AddActor(obj)
    return obj


window = vtk.vtkRenderWindow(); window.SetOffScreenRendering(1)
window.SetSize(2000, 1320); window.SetMultiSamples(8); window.SetNumberOfLayers(3)
background = vtk.vtkRenderer(); background.SetBackground(*BG); background.SetLayer(0)
window.AddRenderer(background)


def scene(viewport, position, target, scale):
    renderer = vtk.vtkRenderer(); renderer.SetLayer(1); renderer.SetViewport(*viewport)
    window.AddRenderer(renderer)
    camera = renderer.GetActiveCamera(); camera.SetPosition(*position)
    camera.SetFocalPoint(*target); camera.SetViewUp(0,0,1)
    camera.ParallelProjectionOn(); camera.SetParallelScale(scale)
    return renderer


hero = scene((0.015,0.17,0.645,0.86),(600,720,530),(0,0,-20),245)
for name in instances:
    if name == 'chassis': color = CYAN
    elif 'inner_spacer' in name or 'pivot_shaft' in name: color = ORANGE
    elif name.endswith('_wheel'): color = (0.28,0.34,0.40)
    elif 'rocker' in name or 'bogie' in name: color = (0.66,0.72,0.77)
    else: color = STEEL
    actor(hero,name,color,positioned=True)
hero.ResetCameraClippingRange()

hub = scene((0.655,0.49,0.98,0.845),(85,65,55),(0,-3,0),37)
# Keep the negative-X half of the hub, cropped to omit the wheel rim.
actor(hub,'left_front_wheel',(0.68,0.75,0.80),planes=[
    ((0,0,0),(-1,0,0)), ((-25,0,0),(1,0,0)),
    ((0,0,-23),(0,0,1)), ((0,0,23),(0,0,-1)),
])
actor(hub,'left_front_bearings',STEEL)
actor(hub,'left_front_inner_spacer',ORANGE)
# The bore remains open so the internal sleeve can be seen clearly.
hub.ResetCameraClippingRange()

shaft = scene((0.655,0.19,0.98,0.38),(65,-93.75,180),(0,-93.75,0),24)
actor(shaft,'left_rocker_pivot_shaft',STEEL,keyways=True)
shaft.ResetCameraClippingRange()

overlay = vtk.vtkRenderer(); overlay.SetLayer(2); overlay.InteractiveOff()
window.AddRenderer(overlay)


def text(label, x, y, size=25, color=INK, bold=False):
    obj = vtk.vtkTextActor(); obj.SetInput(label); obj.SetDisplayPosition(x,y)
    prop = obj.GetTextProperty(); prop.SetFontFamilyToArial(); prop.SetFontSize(size)
    prop.SetColor(*color); prop.SetBold(bold)
    overlay.AddActor2D(obj)


text('yapRover / geometry update',60,1230,49,bold=True)
text('Actual CAD geometry  |  Level suspension pose',63,1185,25,color=(0.38,0.45,0.51))
text('01  ONE-PIECE CHASSIS',60,1090,28,CYAN,True)
text('Integral bearing housings; former split seam removed',60,1048,23)
text('205 x 195 x 110 mm',65,260,32,CYAN,True)
text('5 mm brim: 215 x 205 mm usable bed area',65,217,23)
text('02  WHEEL HUB CUTAWAY',1320,1120,28,INK,True)
text('Internal metal spacer highlighted in orange',1320,1078,22)
text('21.4 mm long  |  12 mm OD  |  8.3 mm bore',1320,624,23,ORANGE,True)
text('Outer rim and half of hub omitted to expose the stack',1320,587,20)
text('03  MACHINED ROCKER SHAFT',1320,511,28,INK,True)
text('Two keyways; cut faces highlighted in orange',1320,470,22)
text('2.05 mm slot width  |  1.20 mm modeled depth',1320,212,23,ORANGE,True)
text('CYAN  Updated chassis       ORANGE  Added spacer / modified shaft',65,112,25,bold=True)
text('Detail views enlarged independently. Colors indicate changes, not specified materials.',65,65,22,color=(0.38,0.45,0.51))
OUTPUT.parent.mkdir(exist_ok=True)
window.Render()
capture = vtk.vtkWindowToImageFilter(); capture.SetInput(window)
capture.SetInputBufferTypeToRGB(); capture.ReadFrontBufferOff(); capture.Update()
writer = vtk.vtkPNGWriter(); writer.SetFileName(str(OUTPUT)); writer.SetInputConnection(capture.GetOutputPort()); writer.Write()
print(OUTPUT)
