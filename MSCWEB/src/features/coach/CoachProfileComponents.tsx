import { Linking, Platform, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useEffect, useMemo, useRef, useState } from 'react';

import { useAuth } from '@/shared/auth/AuthProvider';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { Button, Card, Field, InlineMessage, StateView, StatusBadge, UserAvatar } from '@/shared/ui/primitives';
import { getCoachExperienceRepository } from './coach-experience-repository';
import { useCoachProfileDraft, usePublishCoachProfile, useSaveCoachProfileDraft } from './coach-experience-queries';
import type { PublicCoachProfile } from './coach-experience-models';

type DraftForm = {
  handle: string; photoObjectPath: string | null; headline: string; biography: string;
  serviceArea: string; instagram: string; tiktok: string; website: string;
  whatsapp: string; phone: string; showInstagram: boolean; showTiktok: boolean;
  showWebsite: boolean; showWhatsapp: boolean; showPhone: boolean;
};

const emptyForm: DraftForm = { handle: '', photoObjectPath: null, headline: '', biography: '', serviceArea: '', instagram: '', tiktok: '', website: '', whatsapp: '', phone: '', showInstagram: false, showTiktok: false, showWebsite: false, showWhatsapp: false, showPhone: false };

export function CoachProfileEditor({ authorized }: { authorized: boolean }) {
  const { colors } = useAppTheme();
  const { state } = useAuth();
  const profile = useCoachProfileDraft(authorized);
  const save = useSaveCoachProfileDraft();
  const publish = usePublishCoachProfile();
  const [form, setForm] = useState<DraftForm>(emptyForm);
  const [photo, setPhoto] = useState<File>();
  const [photoBusy, setPhotoBusy] = useState(false);
  const [notice, setNotice] = useState<string>();
  const photoInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!profile.data) return;
    const draft = profile.data.draft;
    const nextForm = draft ? {
      handle: draft.public_handle, photoObjectPath: draft.profile_photo_object_path,
      headline: draft.professional_headline, biography: draft.biography,
      serviceArea: draft.service_area, instagram: draft.instagram_url,
      tiktok: draft.tiktok_url, website: draft.website_url,
      whatsapp: draft.whatsapp_number, phone: draft.phone_number,
      showInstagram: draft.show_instagram, showTiktok: draft.show_tiktok,
      showWebsite: draft.show_website, showWhatsapp: draft.show_whatsapp,
      showPhone: draft.show_phone,
    } : { ...emptyForm, handle: slugify(profile.data.identity.display_name) };
    queueMicrotask(() => setForm(nextForm));
  }, [profile.data]);

  const identityPhoto = profile.data?.draft?.profile_photo_object_path
    ? getCoachExperienceRepository().publicMediaUrl(profile.data.draft.profile_photo_object_path)
    : profile.data?.identity.provider_avatar_url ?? undefined;

  if (!authorized) return <StateView kind="forbidden" />;
  if (profile.isPending) return <StateView kind="loading" />;
  if (profile.isError || !profile.data) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void profile.refetch()} />} />;

  const saveDraft = async () => {
    let photoObjectPath = form.photoObjectPath;
    try {
      if (state.status === 'authenticated' && (photo || (!photoObjectPath && profile.data.identity.provider_avatar_url))) {
        setPhotoBusy(true);
        photoObjectPath = photo
          ? await getCoachExperienceRepository().uploadPublicProfileImage(photo, 'avatar')
          : await getCoachExperienceRepository().importProviderAvatar(
            profile.data.identity.provider_avatar_url as string,
          );
      }
      await save.mutateAsync({
        handle: form.handle, photoObjectPath, professionalHeadline: form.headline,
        biography: form.biography, serviceArea: form.serviceArea,
        instagramUrl: form.instagram, tiktokUrl: form.tiktok, websiteUrl: form.website,
        whatsappNumber: form.whatsapp, phoneNumber: form.phone,
        showInstagram: form.showInstagram, showTiktok: form.showTiktok,
        showWebsite: form.showWebsite, showWhatsapp: form.showWhatsapp,
        showPhone: form.showPhone,
      });
      setForm((value) => ({ ...value, photoObjectPath })); setPhoto(undefined);
      if (photoInputRef.current) photoInputRef.current.value = '';
      setNotice('Draf profil tersimpan.');
    } catch (error) { setNotice(error instanceof Error ? error.message : 'Draf belum dapat disimpan.'); }
    finally { setPhotoBusy(false); }
  };

  const publishProfile = async () => {
    try {
      const result = await publish.mutateAsync();
      setNotice(`Profil diterbitkan di /c/${result.handle}`);
    } catch (error) { setNotice(error instanceof Error ? error.message : 'Profil belum dapat diterbitkan.'); }
  };

  const shareProfile = async () => {
    const url = `${window.location.origin}/c/${form.handle}`;
    try {
      if (navigator.share) await navigator.share({ title: `Profil Coach ${profile.data.identity.display_name}`, url });
      else { await navigator.clipboard.writeText(url); setNotice('Tautan profil disalin.'); }
    } catch { setNotice('Tautan belum dapat dibagikan.'); }
  };

  return (
    <ScrollView contentContainerStyle={styles.content} testID="coach.profile.editor">
      <Card>
        <View style={styles.identityRow}>
          <UserAvatar uri={identityPhoto} label={profile.data.identity.display_name} size={88} />
          <View style={styles.flexCopy}><StatusBadge label="Coach terverifikasi" tone="success" /><Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{profile.data.identity.display_name}</Text><Text style={[styles.caption, { color: colors.secondaryText }]}>Nama dan tanda verifikasi berasal dari akun dan tidak dapat diedit di profil publik.</Text></View>
        </View>
        {Platform.OS === 'web' ? <input ref={photoInputRef} aria-label="Ganti foto profil Coach" type="file" accept="image/jpeg,image/png,image/webp,image/heic,image/heif" onChange={(event) => setPhoto(event.currentTarget.files?.[0])} /> : null}
        {photo ? <Text style={[styles.caption, { color: colors.secondaryText }]}>{photo.name}</Text> : null}
      </Card>

      <Card>
        <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>Profil profesional</Text>
        <Field label="Alamat profil" value={form.handle} editable={profile.data.draft === null} onChangeText={(handle) => setForm((value) => ({ ...value, handle: slugify(handle) }))} message={profile.data.draft ? 'Alamat profil stabil dan tidak berubah setelah disimpan.' : 'Gunakan huruf kecil, angka, dan tanda hubung.'} />
        <Field label="Judul profesional" value={form.headline} onChangeText={(headline) => setForm((value) => ({ ...value, headline }))} maxLength={120} />
        <Field label="Cerita atau biografi" value={form.biography} onChangeText={(biography) => setForm((value) => ({ ...value, biography }))} multiline maxLength={2000} />
        <Field label="Kota atau area layanan" value={form.serviceArea} onChangeText={(serviceArea) => setForm((value) => ({ ...value, serviceArea }))} maxLength={120} />
      </Card>

      <Card>
        <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>Kontak publik</Text>
        <ContactField label="Instagram" value={form.instagram} visible={form.showInstagram} onChange={(instagram) => setForm((value) => ({ ...value, instagram }))} onToggle={() => setForm((value) => ({ ...value, showInstagram: !value.showInstagram }))} />
        <ContactField label="TikTok" value={form.tiktok} visible={form.showTiktok} onChange={(tiktok) => setForm((value) => ({ ...value, tiktok }))} onToggle={() => setForm((value) => ({ ...value, showTiktok: !value.showTiktok }))} />
        <ContactField label="Situs web" value={form.website} visible={form.showWebsite} onChange={(website) => setForm((value) => ({ ...value, website }))} onToggle={() => setForm((value) => ({ ...value, showWebsite: !value.showWebsite }))} />
        <ContactField label="WhatsApp" value={form.whatsapp} visible={form.showWhatsapp} onChange={(whatsapp) => setForm((value) => ({ ...value, whatsapp }))} onToggle={() => setForm((value) => ({ ...value, showWhatsapp: !value.showWhatsapp }))} />
        <ContactField label="Telepon" value={form.phone} visible={form.showPhone} onChange={(phone) => setForm((value) => ({ ...value, phone }))} onToggle={() => setForm((value) => ({ ...value, showPhone: !value.showPhone }))} />
        <InlineMessage title="Kontrol privasi" message="Nilai yang tidak diaktifkan tidak disalin ke snapshot publik dan tidak dikirim ke Tamu." />
      </Card>

      <ProfileItemEditor onSaved={() => void profile.refetch()} />
      {profile.data.items.length ? <Card><Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>Moderasi konten</Text>{profile.data.items.map((item) => <View key={item.id} style={styles.itemRow}><Text style={[styles.bodyStrong, { color: colors.primaryText }]}>{item.title}</Text><StatusBadge label={item.moderation_status === 'pending' ? 'Menunggu moderasi' : item.moderation_status === 'approved' ? 'Disetujui' : 'Ditolak'} tone={item.moderation_status === 'approved' ? 'success' : item.moderation_status === 'rejected' ? 'destructive' : 'warning'} />{item.moderation_note ? <Text style={[styles.caption, { color: colors.secondaryText }]}>{item.moderation_note}</Text> : null}</View>)}</Card> : null}

      {notice ? <InlineMessage title="Status profil" message={notice} tone={notice.includes('belum') ? 'destructive' : 'success'} /> : null}
      <Button label="Simpan draf" loading={save.isPending || photoBusy} disabled={form.handle.length < 3} onPress={() => void saveDraft()} />
      <Button label={profile.data.published ? 'Perbarui profil publik' : 'Terbitkan profil'} tone="secondary" loading={publish.isPending} onPress={() => void publishProfile()} />
      {profile.data.published ? <Button label="Bagikan profil" icon="copy" tone="secondary" onPress={() => void shareProfile()} /> : null}
    </ScrollView>
  );
}

function ContactField({ label, value, visible, onChange, onToggle }: { label: string; value: string; visible: boolean; onChange: (value: string) => void; onToggle: () => void }) {
  const { colors } = useAppTheme();
  return <View style={styles.contactRow}><View style={styles.flexCopy}><Field label={label} value={value} onChangeText={onChange} /></View><Pressable accessibilityRole="switch" accessibilityState={{ checked: visible }} aria-checked={visible} onPress={onToggle} style={[styles.toggle, { backgroundColor: visible ? colors.primaryAction : colors.secondaryBackground, borderColor: visible ? colors.primaryAction : colors.border }]}><Text style={{ color: visible ? '#ffffff' : colors.primaryText }}>{visible ? 'Publik' : 'Privat'}</Text></Pressable></View>;
}

function ProfileItemEditor({ onSaved }: { onSaved: () => void }) {
  const { colors } = useAppTheme();
  const [kind, setKind] = useState<'testimonial' | 'before_after'>('testimonial');
  const [title, setTitle] = useState(''); const [body, setBody] = useState('');
  const [includesThirdParty, setIncludesThirdParty] = useState(false); const [permission, setPermission] = useState(false);
  const [file, setFile] = useState<File>(); const [busy, setBusy] = useState(false); const [message, setMessage] = useState<string>();
  const submit = async () => {
    setBusy(true); setMessage(undefined);
    try {
      const mediaObjectPath = file ? await getCoachExperienceRepository().uploadPublicProfileImage(file, 'items') : null;
      await getCoachExperienceRepository().submitProfileItem({ kind, title, body, mediaObjectPath, includesThirdParty, permissionAttested: permission });
      setTitle(''); setBody(''); setFile(undefined); setMessage('Konten dikirim untuk moderasi.'); onSaved();
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Konten belum dapat dikirim.'); }
    finally { setBusy(false); }
  };
  return <Card><Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>Testimoni dan sebelum–sesudah</Text><View style={styles.kindRow}><Choice label="Testimoni" selected={kind === 'testimonial'} onPress={() => setKind('testimonial')} /><Choice label="Sebelum–sesudah" selected={kind === 'before_after'} onPress={() => setKind('before_after')} /></View><Field label="Judul" value={title} onChangeText={setTitle} /><Field label="Cerita singkat" value={body} onChangeText={setBody} multiline />{Platform.OS === 'web' ? <input aria-label="Pilih media profil publik" type="file" accept="image/jpeg,image/png,image/webp,image/heic,image/heif" onChange={(event) => setFile(event.currentTarget.files?.[0])} /> : null}<Check label="Konten menampilkan atau mengutip orang lain" checked={includesThirdParty} onPress={() => { setIncludesThirdParty((value) => !value); if (includesThirdParty) setPermission(false); }} />{includesThirdParty ? <Check label="Saya memiliki izin orang tersebut untuk publikasi" checked={permission} onPress={() => setPermission((value) => !value)} /> : null}<InlineMessage title="Moderasi wajib" message="Konten baru tidak tampil ke publik sebelum Admin menyetujuinya. Konten diri sendiri tidak memerlukan pernyataan izin pihak lain." tone="warning" />{message ? <Text style={[styles.caption, { color: colors.secondaryText }]}>{message}</Text> : null}<Button label="Kirim untuk moderasi" loading={busy} disabled={title.trim().length === 0 || (includesThirdParty && !permission)} onPress={() => void submit()} /></Card>;
}

function Choice({ label, selected, onPress }: { label: string; selected: boolean; onPress: () => void }) { const { colors } = useAppTheme(); return <Pressable accessibilityRole="radio" accessibilityState={{ selected }} onPress={onPress} style={[styles.choice, { borderColor: selected ? colors.primaryAction : colors.border, backgroundColor: selected ? colors.secondaryBackground : colors.surface }]}><Text style={[styles.bodyStrong, { color: colors.primaryText }]}>{label}</Text></Pressable>; }
function Check({ label, checked, onPress }: { label: string; checked: boolean; onPress: () => void }) { const { colors } = useAppTheme(); return <Pressable accessibilityRole="checkbox" accessibilityState={{ checked }} aria-checked={checked} onPress={onPress} style={[styles.check, { borderColor: checked ? colors.primaryAction : colors.border }]}><Text style={[styles.body, { color: colors.primaryText }]}>{checked ? '✓ ' : ''}{label}</Text></Pressable>; }

export function PublicCoachProfileView({ profile }: { profile: PublicCoachProfile }) {
  const { colors } = useAppTheme();
  const photo = getCoachExperienceRepository().publicMediaUrl(profile.photo_reference);
  const contacts = useMemo(() => [
    profile.instagram_url && { label: 'Instagram', href: profile.instagram_url },
    profile.tiktok_url && { label: 'TikTok', href: profile.tiktok_url },
    profile.website_url && { label: 'Situs web', href: profile.website_url },
    profile.whatsapp_number && { label: 'WhatsApp', href: `https://wa.me/${profile.whatsapp_number.replace(/\D/gu, '')}` },
    profile.phone_number && { label: 'Telepon', href: `tel:${profile.phone_number}` },
  ].filter(Boolean) as { label: string; href: string }[], [profile]);
  const share = async () => {
    const url = window.location.href;
    if (navigator.share) await navigator.share({ title: `Profil Coach ${profile.display_name}`, url });
    else await navigator.clipboard.writeText(url);
  };
  return <ScrollView contentContainerStyle={styles.publicContent} testID="public.coach.profile"><View style={[styles.publicHero, { backgroundColor: colors.primaryText }]}><UserAvatar uri={photo} label={profile.display_name} size={112} /><StatusBadge label="Coach terverifikasi" tone="success" /><Text accessibilityRole="header" style={[styles.publicTitle, { color: '#ffffff' }]}>{profile.display_name}</Text>{profile.professional_headline ? <Text style={[styles.publicHeadline, { color: '#ffffff' }]}>{profile.professional_headline}</Text> : null}{profile.service_area ? <Text style={[styles.body, { color: '#ffffff' }]}>{profile.service_area}</Text> : null}<Button label="Bagikan profil" icon="copy" onPress={() => void share()} /></View>{profile.biography ? <Card><Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>Tentang Coach</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{profile.biography}</Text></Card> : null}{contacts.length ? <Card><Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>Hubungi</Text><View style={styles.kindRow}>{contacts.map((contact) => <Button key={contact.label} label={contact.label} tone="secondary" onPress={() => void Linking.openURL(contact.href)} />)}</View></Card> : null}{profile.items.length ? <View style={styles.itemGrid}>{profile.items.map((item, index) => <Card key={`${item.kind}-${index}`}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{item.title}</Text>{item.media_object_path ? <UserAvatar uri={getCoachExperienceRepository().publicMediaUrl(item.media_object_path)} label={item.title} size={96} /> : null}{item.body ? <Text style={[styles.body, { color: colors.secondaryText }]}>{item.body}</Text> : null}</Card>)}</View> : null}</ScrollView>;
}

function slugify(value: string) { return value.toLowerCase().normalize('NFKD').replace(/[\u0300-\u036f]/gu, '').replace(/[^a-z0-9]+/gu, '-').replace(/^-|-$/gu, '').slice(0, 48); }

const styles = StyleSheet.create({
  content: { width: '100%', maxWidth: 860, alignSelf: 'center', padding: primitiveTokens.space.large, paddingBottom: 150, gap: primitiveTokens.space.large },
  publicContent: { width: '100%', maxWidth: 960, alignSelf: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.large },
  publicHero: { borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.xLarge, alignItems: 'center', gap: primitiveTokens.space.medium },
  identityRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xSmall },
  contactRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small },
  toggle: { minWidth: 76, minHeight: 44, borderWidth: 1, borderRadius: primitiveTokens.radius.capsule, alignItems: 'center', justifyContent: 'center', paddingHorizontal: primitiveTokens.space.small },
  kindRow: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  choice: { flexGrow: 1, minHeight: 48, borderWidth: 2, borderRadius: primitiveTokens.radius.medium, justifyContent: 'center', alignItems: 'center', padding: primitiveTokens.space.small },
  check: { minHeight: 48, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, justifyContent: 'center' },
  itemRow: { gap: primitiveTokens.space.xSmall, borderTopWidth: StyleSheet.hairlineWidth, paddingTop: primitiveTokens.space.small },
  itemGrid: { gap: primitiveTokens.space.medium },
  heading: typographyTokens.title,
  cardTitle: typographyTokens.headline,
  body: typographyTokens.body,
  bodyStrong: typographyTokens.bodyStrong,
  caption: typographyTokens.caption,
  publicTitle: { fontSize: 38, lineHeight: 44, fontWeight: '900', textAlign: 'center' },
  publicHeadline: { ...typographyTokens.headline, textAlign: 'center' },
});
