// Impact effect for dragon's breath bullets
class FAShotgunImpactEffect extends Emitter;//FlameImpact_Medium extends FlameImpact;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseColorScale=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         Acceleration=(Z=15.000000)
         ColorScale(0)=(Color=(B=51,G=152,R=200))
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=48,G=91,R=222))
         ColorScale(2)=(RelativeTime=1.000000)
         MaxParticles=2
         StartLocationShape=PTLS_Sphere
         MeshScaleRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.500000,Max=0.500000))
         SpinsPerSecondRange=(X=(Max=0.100000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.700000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=5.000000)
         StartSizeRange=(X=(Min=5.000000,Max=10.000000),Y=(Min=10.000000,Max=10.000000),Z=(Min=10.000000,Max=10.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
         TextureUSubdivisions=8
         TextureVSubdivisions=8
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.000000,Max=1.000000)
         StartVelocityRange=(X=(Min=-50.000000,Max=50.000000),Y=(Min=-50.000000,Max=50.000000),Z=(Min=25.000000,Max=50.000000))
     End Object
     Emitters(0)=SpriteEmitter'MutSR.FAShotgunImpactEffect.SpriteEmitter0'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter1
         UseColorScale=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         Acceleration=(Z=150.000000)
         ColorScale(0)=(Color=(G=255,R=255,A=128))
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=47,G=80,R=179,A=255))
         ColorScale(2)=(RelativeTime=0.600000,Color=(A=80))
         ColorScale(3)=(RelativeTime=1.000000)
         MaxParticles=2
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=10.000000,Max=10.000000)
         SpinsPerSecondRange=(X=(Max=0.100000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.700000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=5.000000)
         StartSizeRange=(X=(Min=10.000000,Max=20.000000),Y=(Min=10.000000,Max=20.000000),Z=(Min=50.000000,Max=50.000000))
         InitialParticlesPerSecond=800.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
         TextureUSubdivisions=8
         TextureVSubdivisions=8
         LifetimeRange=(Min=1.000000,Max=1.000000)
         StartVelocityRange=(X=(Min=-100.000000,Max=100.000000),Y=(Min=-100.000000,Max=100.000000))
     End Object
     Emitters(1)=SpriteEmitter'MutSR.FAShotgunImpactEffect.SpriteEmitter1'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter2
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         BlendBetweenSubdivisions=True
         UseSubdivisionScale=True
         Acceleration=(Z=50.000000)
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         FadeOutStartTime=0.102500
         FadeInEndTime=0.050000
         MaxParticles=2
         SizeScale(1)=(RelativeTime=0.140000,RelativeSize=1.000000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=3.000000)
         StartSizeRange=(X=(Min=10.000000,Max=10.000000),Y=(Min=10.000000,Max=10.000000),Z=(Min=10.000000,Max=10.000000))
         InitialParticlesPerSecond=30.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'Effects_Tex.explosions.impact_2frame'
         TextureUSubdivisions=2
         TextureVSubdivisions=1
         LifetimeRange=(Min=0.200000,Max=0.200000)
         StartVelocityRange=(Z=(Min=10.000000,Max=10.000000))
     End Object
     Emitters(2)=SpriteEmitter'MutSR.FAShotgunImpactEffect.SpriteEmitter2'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter3
         FadeOut=True
         FadeIn=True
         Disabled=True
         Backup_Disabled=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=100.000000)
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255))
         ColorScale(2)=(RelativeTime=0.667857,Color=(B=89,G=172,R=247,A=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=128,G=128,R=128,A=255))
         ColorScale(4)=(RelativeTime=1.000000)
         ColorScale(5)=(RelativeTime=1.000000)
         FadeOutStartTime=0.520000
         FadeInEndTime=0.140000
         MaxParticles=8
         StartLocationShape=PTLS_Sphere
         SpinsPerSecondRange=(X=(Max=0.075000))
         StartSpinRange=(X=(Min=-0.500000,Max=0.500000))
         SizeScale(0)=(RelativeTime=1.000000,RelativeSize=0.500000)
         StartSizeRange=(X=(Min=15.000000,Max=15.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
         ScaleSizeByVelocityMax=0.000000
         Texture=Texture'KillingFloorTextures.LondonCommon.fire3'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=1.000000,Max=1.000000)
         StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=25.000000,Max=75.000000))
     End Object
     Emitters(3)=SpriteEmitter'MutSR.FAShotgunImpactEffect.SpriteEmitter3'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter4
         UseDirectionAs=PTDU_Up
         UseCollision=True
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         UseRegularSizeScale=False
         UniformSize=True
         ScaleSizeYByVelocity=True
         AutomaticInitialSpawning=False
         BlendBetweenSubdivisions=True
         UseRandomSubdivision=True
         Acceleration=(Z=-500.000000)
         ColorScale(0)=(Color=(B=200,G=255,R=255))
         ColorScale(1)=(RelativeTime=0.200000,Color=(B=190,G=220,R=242))
         ColorScale(2)=(RelativeTime=0.400000,Color=(B=200,G=255,R=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=200,G=255,R=255))
         FadeOutStartTime=0.800000
         MaxParticles=3
         SizeScale(2)=(RelativeTime=0.070000,RelativeSize=1.000000)
         SizeScale(3)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=3.000000,Max=3.000000),Y=(Min=3.000000,Max=3.000000),Z=(Min=3.000000,Max=3.000000))
         ScaleSizeByVelocityMultiplier=(Y=0.005000)
         InitialParticlesPerSecond=500.000000
         Texture=Texture'KFX.KFSparkHead'
         TextureUSubdivisions=1
         TextureVSubdivisions=2
         LifetimeRange=(Min=0.700000,Max=1.000000)
         StartVelocityRange=(X=(Min=-500.000000,Max=500.000000),Y=(Min=-500.000000,Max=500.000000),Z=(Max=500.000000))
     End Object
     Emitters(4)=SpriteEmitter'MutSR.FAShotgunImpactEffect.SpriteEmitter4'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter5
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         UseRandomSubdivision=True
         Acceleration=(Z=125.000000)
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255))
         ColorScale(2)=(RelativeTime=0.667857,Color=(B=89,G=172,R=247,A=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=128,G=128,R=128,A=255))
         ColorScale(4)=(RelativeTime=1.000000)
         ColorScale(5)=(RelativeTime=1.000000)
         FadeOutStartTime=0.200000
         FadeInEndTime=0.140000
         MaxParticles=2
         StartLocationRange=(Z=(Min=25.000000,Max=25.000000))
         SpinsPerSecondRange=(X=(Max=0.100000))
         StartSpinRange=(X=(Min=-0.500000,Max=0.500000))
         SizeScale(0)=(RelativeTime=1.000000,RelativeSize=1.500000)
         StartSizeRange=(X=(Min=20.000000,Max=30.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
         ScaleSizeByVelocityMax=0.000000
         InitialParticlesPerSecond=5000.000000
         Texture=Texture'KillingFloorTextures.LondonCommon.fire3'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=0.500000,Max=0.500000)
         StartVelocityRange=(Z=(Min=30.000000,Max=30.000000))
     End Object
     Emitters(5)=SpriteEmitter'MutSR.FAShotgunImpactEffect.SpriteEmitter5'

     bNoDelete=False
     LifeSpan=3.000000
}
