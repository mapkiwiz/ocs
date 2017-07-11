import pandas as pd
import os

T_EXPO_CLASSES = [ 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N' ]
def t_expo(expo):
    return T_EXPO_CLASSES[int((expo % 360 + 22.5) // 45)]

def update(dep):
    df = pd.DataFrame.from_csv(os.path.join(dep, 'relief.csv'))
    df['t_expo'] = map(t_expo, df['expo'])
    df.to_csv(os.path.join(dep, 'relief.csv'))
    df.describe().to_csv(os.path.join(dep, 'relief_summary.csv'))