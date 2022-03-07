Class MutSR_SRClientSettings extends Object
	PerObjectConfig
	Config(MutSR_ServerPerksClient);

var private transient MutSR_SRClientSettings Ref;

var config array<name> Fav;

static final function MutSR_SRClientSettings GetSettings()
{
	if( Default.Ref==None )
		Default.Ref = New(None,"Settings")Class'MutSR_SRClientSettings';
	return Default.Ref;
}

static final function bool IsFavorite( class<Pickup> WC )
{
	local MutSR_SRClientSettings S;
	local int i;
	
	S = GetSettings();
	for( i=0; i<S.Fav.Length; ++i )
		if( S.Fav[i]==WC.Name )
			return true;
	return false;
}
static final function AddFavorite( class<Pickup> WC )
{
	local MutSR_SRClientSettings S;
	local int i;
	
	S = GetSettings();
	for( i=0; i<S.Fav.Length; ++i )
		if( S.Fav[i]==WC.Name )
			return;
	S.Fav.Length = i+1;
	S.Fav[i] = WC.Name;
	S.SaveConfig();
}
static final function RemoveFavorite( class<Pickup> WC )
{
	local MutSR_SRClientSettings S;
	local int i;
	
	S = GetSettings();
	for( i=0; i<S.Fav.Length; ++i )
		if( S.Fav[i]==WC.Name )
		{
			S.Fav.Remove(i,1);
			S.SaveConfig();
			return;
		}
}
